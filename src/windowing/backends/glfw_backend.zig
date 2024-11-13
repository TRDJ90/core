const glfw = @import("../../c.zig");

pub const Window = struct {
    window: *glfw.GLFWwindow,

    pub fn init(width: u32, height: u32, title: [:0]const u8) !Window {
        if (glfw.glfwInit() != glfw.GLFW_TRUE) return error.WindowCreationFailed;
        glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);

        const glfw_window = glfw.glfwCreateWindow(
            @intCast(width),
            @intCast(height),
            title,
            null,
            null,
        ) orelse return error.WindowCreationFailed;

        return .{
            .window = glfw_window,
        };
    }

    pub fn deinit(self: *const Window) void {
        glfw.glfwDestroyWindow(self.window);
        glfw.glfwTerminate();
    }

    pub fn windowClosed(self: *const Window) bool {
        return glfw.glfwWindowShouldClose(self.window) == glfw.GLFW_TRUE;
    }

    pub fn update(self: *const Window) void {
        _ = self;
        glfw.glfwPollEvents();
    }
};
