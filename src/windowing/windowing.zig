const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Backend = @import("./backends/glfw_backend.zig");

pub const Window = struct {
    pub fn init(width: u32, height: u32, title: [:0]const u8) !void {
        try Backend.init(
            width,
            height,
            title,
        );
    }

    pub fn deinit() void {
        Backend.deinit();
    }

    pub fn windowClosed() bool {
        return Backend.windowClosed();
    }

    pub fn update() void {
        Backend.update();
    }

    pub fn getWindowPtr() *anyopaque {
        return Backend.getWindowPtr();
    }

    pub fn getWindowVulkanExtensions(exts_list: *ArrayList([*:0]const u8)) !void {
        return Backend.getVulkanExtensions(exts_list);
    }
};
