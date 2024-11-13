const std = @import("std");
const assert = std.debug.assert;

const glfw = @import("../../c.zig");

var window: ?*glfw.GLFWwindow = null;

pub fn init(width: u32, height: u32, title: [:0]const u8) !void {
    if (glfw.glfwInit() != glfw.GLFW_TRUE) return error.WindowCreationFailed;
    glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

    const glfw_window = glfw.glfwCreateWindow(
        @intCast(width),
        @intCast(height),
        title,
        null,
        null,
    ) orelse return error.WindowCreationFailed;

    window = glfw_window;
}

pub fn deinit() void {
    assert(window != null);

    glfw.glfwDestroyWindow(window);
    glfw.glfwTerminate();
}

pub fn windowClosed() bool {
    assert(window != null);

    return glfw.glfwWindowShouldClose(window) == glfw.GLFW_TRUE;
}

pub fn update() void {
    assert(window != null);

    glfw.glfwPollEvents();
}

pub fn getVulkanExtensions(allocator: std.mem.Allocator) std.ArrayList {
    assert(window != null);

    var vk_exts_count: u32 = 0;
    const vk_exts = glfw.glfwGetRequiredInstanceExtensions(&vk_exts_count);

    var vk_exts_list = try std.ArrayList([*:0]const u8).initCapacity(allocator, vk_exts_count);
    for (0..vk_exts_count) |i| {
        try vk_exts_list.append(vk_exts[i]);
    }
}
