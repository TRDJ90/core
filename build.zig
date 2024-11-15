const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Setup vulkan-zig generator and module.
    const registry = b.dependency("vulkan_headers", .{}).path("registry/vk.xml");
    const vk_gen = b.dependency("vulkan_zig", .{}).artifact("vulkan-zig-generator");
    const vk_generate_cmd = b.addRunArtifact(vk_gen);
    vk_generate_cmd.addFileArg(registry);

    const vulkan_zig = b.addModule("vulkan-zig", .{
        .root_source_file = vk_generate_cmd.addOutputFileArg("vk.zig"),
    });

    const core = b.addStaticLibrary(.{
        .name = "core",
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
    });
    core.linkSystemLibrary("glfw3");
    core.root_module.addImport("vulkan", vulkan_zig);

    const test_bed = b.addExecutable(.{
        .name = "testbed",
        .root_source_file = b.path("testbed/testbed.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_bed.root_module.addImport("core", &core.root_module);
    b.installArtifact(test_bed);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_cmd = b.addRunArtifact(test_bed);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "run the testbed");
    run_step.dependOn(&run_cmd.step);

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
