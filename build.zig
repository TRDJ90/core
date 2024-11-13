const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core = b.addStaticLibrary(.{
        .name = "core",
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
    });
    core.linkSystemLibrary("glfw3");
    //b.installArtifact(core);

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
