const std = @import("std");
const core = @import("core");

const Window = core.Window;
const VulkanDevice = core.Renderer.Vulkan.VulkanDevice;
const test_bed_name = "Testbed";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const height: u32 = 720;
    const width: u32 = 1280;

    _ = try Window.init(width, height, test_bed_name);
    defer Window.deinit();

    const vulkan_device = try VulkanDevice.init(
        allocator,
        test_bed_name,
    );

    vulkan_device.deinit();

    while (Window.windowClosed() != true) {
        Window.update();
    }
}
