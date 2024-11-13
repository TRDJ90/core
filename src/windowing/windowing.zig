const std = @import("std");

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
};
