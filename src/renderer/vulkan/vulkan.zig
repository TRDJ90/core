const vk = @import("vulkan");

pub const VulkanDevice = @import("vulkan_device.zig").VulkanDevice;
pub const VulkanSwapchain = @import("vulkan_swapchain.zig");

const base_commands: vk.BaseCommandFlags = .{
    .createInstance = true,
    .getInstanceProcAddr = true,
    .enumerateInstanceLayerProperties = true,
};

const instance_commands: vk.InstanceCommandFlags = .{
    .destroyInstance = true,
    .createDevice = true,
    .getDeviceProcAddr = true,
    .enumeratePhysicalDevices = true,
    .enumerateDeviceExtensionProperties = true,
    .getPhysicalDeviceFeatures = true,
    .getPhysicalDeviceProperties = true,
    .getPhysicalDeviceMemoryProperties = true,
    .getPhysicalDeviceQueueFamilyProperties = true,
};

const device_commands: vk.DeviceCommandFlags = .{
    .destroyDevice = true,
    .getDeviceQueue = true,
};

const apis: []const vk.ApiInfo = &.{
    .{
        .base_commands = base_commands,
        .instance_commands = instance_commands,
        .device_commands = device_commands,
    },
    vk.features.version_1_2,
    vk.extensions.khr_surface,
    vk.extensions.khr_swapchain,
    vk.extensions.khr_portability_enumeration,
};

pub const BaseDispatch = vk.BaseWrapper(apis);
pub const InstanceDispatch = vk.InstanceWrapper(apis);
pub const DeviceDispatch = vk.DeviceWrapper(apis);

pub const Instance = vk.InstanceProxy(apis);
pub const Device = vk.DeviceProxy(apis);
