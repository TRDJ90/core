const std = @import("std");
const assert = std.debug.assert;

const Backend = @import("./backends/glfw_backend.zig").Window;

var backend: ?Backend = null;

pub const Window = struct {
    pub fn init(width: u32, height: u32, title: [:0]const u8) !Window {
        if (backend == null) {
            backend = try Backend.init(width, height, title);
        }

        return .{};
    }

    pub fn deinit() void {
        assert(backend != null);
        backend.?.deinit();
    }

    pub fn windowClosed() bool {
        assert(backend != null);
        return backend.?.windowClosed();
    }

    pub fn update() void {
        assert(backend != null);
        backend.?.update();
    }
};
