const std = @import("std");
const core = @import("core");

const Window = core.Window;
const test_bed_name = "Testbed";

pub fn main() !void {
    const height: u32 = 720;
    const width: u32 = 1280;

    _ = try Window.init(width, height, test_bed_name);
    defer Window.deinit();

    while (Window.windowClosed() != true) {
        Window.update();
    }
}
