const std = @import("std");
const vk = @import("vulkan");
const vulkan = @import("vulkan.zig");
const c = @import("../../c.zig");
const Window = @import("../../windowing/windowing.zig").Window;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const BaseDispatch = vulkan.BaseDispatch;
const InstanceDispatch = vulkan.InstanceDispatch;
const DeviceDispatch = vulkan.DeviceDispatch;
const Instance = vulkan.Instance;
const Device = vulkan.Device;

const required_device_extensions = [_][*:0]const u8{
    vk.extensions.khr_swapchain.name,
};

const Queue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(device: Device, family: u32) Queue {
        return .{
            .handle = device.getDeviceQueue(family, 0),
            .family = family,
        };
    }
};

const DeviceCandidate = struct {
    physical_device: vk.PhysicalDevice,
    properties: vk.PhysicalDeviceProperties,
    queues: QueueAllocation,
};

const QueueAllocation = struct {
    graphics_family: u32,
    present_family: u32,
};

pub const VulkanDevice = struct {
    allocator: Allocator,
    vk_base_dispatcher: BaseDispatch,
    instance: Instance,
    device: Device,
    graphics_queue: Queue,
    present_queue: Queue,

    surface: vk.SurfaceKHR,
    physical_device: vk.PhysicalDevice,
    physical_device_props: vk.PhysicalDeviceProperties,
    physical_device_mem_props: vk.PhysicalDeviceMemoryProperties,
    command_pool: vk.CommandPool,

    pub fn init(
        allocator: Allocator,
        app_name: [*:0]const u8,
    ) !VulkanDevice {
        var self: VulkanDevice = undefined;
        self.allocator = allocator;

        var extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, 4);
        try extensions.append(vk.extensions.khr_portability_enumeration.name);
        defer extensions.deinit();

        _ = try Window.getWindowVulkanExtensions(&extensions);
        self.vk_base_dispatcher = try BaseDispatch.load(c.glfwGetInstanceProcAddress);

        // Create vulkan instance
        // TODO: maybe move to a createInstance function..
        const app_info: vk.ApplicationInfo = .{
            .p_application_name = app_name,
            .p_engine_name = app_name,
            .application_version = vk.makeApiVersion(0, 0, 0, 0),
            .engine_version = vk.makeApiVersion(0, 0, 0, 0),
            .api_version = vk.API_VERSION_1_2,
        };

        const instance_create_info: vk.InstanceCreateInfo = .{
            .p_application_info = &app_info,
            .enabled_extension_count = @intCast(extensions.items.len),
            .pp_enabled_extension_names = @ptrCast(extensions.items),
            .flags = vk.InstanceCreateFlags{
                .enumerate_portability_bit_khr = true,
            },
        };

        const instance = try self.vk_base_dispatcher.createInstance(&instance_create_info, null);

        const vk_instance_dispatcher = try allocator.create(InstanceDispatch);
        errdefer allocator.destroy(vk_instance_dispatcher);

        vk_instance_dispatcher.* = try InstanceDispatch.load(instance, self.vk_base_dispatcher.dispatch.vkGetInstanceProcAddr);
        self.instance = Instance.init(instance, vk_instance_dispatcher);
        errdefer self.instance.destroyInstance(null);

        // Create a vulkan surface.
        self.surface = try createSurface(self.instance, @ptrCast(Window.getWindowPtr()));
        errdefer self.instance.destroySurfaceKHR(self.surface, null);

        // Find a candidate device.
        const candidate = try pickPhysicalDevice(self.instance, allocator, self.surface);
        self.physical_device = candidate.physical_device;
        self.physical_device_props = candidate.properties;
        self.physical_device_mem_props = self.instance.getPhysicalDeviceMemoryProperties(self.physical_device);

        const device = try initCandidate(self.instance, candidate);

        const vk_device_dispatcher = try allocator.create(DeviceDispatch);
        errdefer allocator.destroy(vk_device_dispatcher);
        vk_device_dispatcher.* = try DeviceDispatch.load(device, self.instance.wrapper.dispatch.vkGetDeviceProcAddr);
        self.device = Device.init(device, vk_device_dispatcher);
        errdefer self.device.destroyDevice(null);

        // Create device queues
        self.graphics_queue = Queue.init(self.device, candidate.queues.graphics_family);
        self.present_queue = Queue.init(self.device, candidate.queues.present_family);

        return self;
    }

    pub fn deinit(self: VulkanDevice) void {
        self.device.destroyDevice(null);
        self.instance.destroySurfaceKHR(self.surface, null);
        self.instance.destroyInstance(null);

        // Don't forget to free the tables to prevent a memory leak
        self.allocator.destroy(self.device.wrapper);
        self.allocator.destroy(self.instance.wrapper);
    }

    fn createSurface(instance: Instance, window: *c.GLFWwindow) !vk.SurfaceKHR {
        var surface: vk.SurfaceKHR = undefined;
        if (c.glfwCreateWindowSurface(instance.handle, window, null, &surface) != .success) {
            return error.SurfaceInitFailed;
        }

        return surface;
    }

    fn pickPhysicalDevice(
        instance: Instance,
        allocator: Allocator,
        surface: vk.SurfaceKHR,
    ) !DeviceCandidate {
        const physical_devices = try instance.enumeratePhysicalDevicesAlloc(allocator);
        defer allocator.free(physical_devices);

        for (physical_devices) |device| {
            if (try checkSuitable(instance, device, allocator, surface)) |candidate| {
                return candidate;
            }
        }

        return error.NoSuitableDeviceFound;
    }

    fn checkSuitable(
        instance: Instance,
        physical_device: vk.PhysicalDevice,
        allocator: Allocator,
        surface: vk.SurfaceKHR,
    ) !?DeviceCandidate {
        if (!try checkExtensionSupport(instance, physical_device, allocator)) {
            return null;
        }

        if (!try checkSurfaceSupport(instance, physical_device, surface)) {
            return null;
        }

        if (try allocateQueues(instance, physical_device, allocator, surface)) |allocation| {
            const props = instance.getPhysicalDeviceProperties(physical_device);
            std.debug.print("{any}", .{props});

            return DeviceCandidate{
                .physical_device = physical_device,
                .properties = props,
                .queues = allocation,
            };
        }

        return null;
    }

    fn checkExtensionSupport(
        instance: Instance,
        physical_device: vk.PhysicalDevice,
        allocator: Allocator,
    ) !bool {
        const properties = try instance.enumerateDeviceExtensionPropertiesAlloc(physical_device, null, allocator);
        defer allocator.free(properties);

        for (required_device_extensions) |ext| {
            for (properties) |property| {
                if (std.mem.eql(u8, std.mem.span(ext), std.mem.sliceTo(&property.extension_name, 0))) {
                    break;
                }
            } else {
                return false;
            }
        }

        return true;
    }

    fn checkSurfaceSupport(instance: Instance, physical_device: vk.PhysicalDevice, surface: vk.SurfaceKHR) !bool {
        var format_count: u32 = undefined;
        _ = try instance.getPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &format_count, null);

        var present_mode_count: u32 = undefined;
        _ = try instance.getPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &present_mode_count, null);

        return format_count > 0 and present_mode_count > 0;
    }

    fn allocateQueues(
        instance: Instance,
        physical_device: vk.PhysicalDevice,
        allocator: Allocator,
        surface: vk.SurfaceKHR,
    ) !?QueueAllocation {
        const families = try instance.getPhysicalDeviceQueueFamilyPropertiesAlloc(physical_device, allocator);
        defer allocator.free(families);

        // TODO: Expand to include other queue families.
        var graphics_family: ?u32 = null;
        var present_family: ?u32 = null;

        for (families, 0..) |properties, i| {
            const family: u32 = @intCast(i);

            // switch (properties.queue_flags) {
            //     .graphics_bit => graphics_family = family,
            //     else => unreachable,
            // }

            if (graphics_family == null and properties.queue_flags.graphics_bit) {
                graphics_family = family;
            }

            if (present_family == null and (try instance.getPhysicalDeviceSurfaceSupportKHR(physical_device, family, surface)) == vk.TRUE) {
                present_family = family;
            }
        }

        if (graphics_family != null and present_family != null) {
            return QueueAllocation{
                .graphics_family = graphics_family.?,
                .present_family = present_family.?,
            };
        }

        return null;
    }

    fn initCandidate(instance: Instance, candidate: DeviceCandidate) !vk.Device {
        const priority = [_]f32{1};
        const qci = [_]vk.DeviceQueueCreateInfo{
            .{
                .queue_family_index = candidate.queues.graphics_family,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
            .{
                .queue_family_index = candidate.queues.present_family,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
        };

        const queue_count: u32 = if (candidate.queues.graphics_family == candidate.queues.present_family)
            // Graphics and present queue are the same queue.
            1
        else
            2;

        const dci: vk.DeviceCreateInfo = .{
            .queue_create_info_count = queue_count,
            .p_queue_create_infos = &qci,
            .enabled_extension_count = required_device_extensions.len,
            .pp_enabled_extension_names = @ptrCast(&required_device_extensions),
        };

        return try instance.createDevice(
            candidate.physical_device,
            &dci,
            null,
        );
    }
};
