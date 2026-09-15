const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vaxis = b.dependency("vaxis", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("zetesis", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });
    mod.addImport("vaxis", vaxis.module("vaxis"));

    const exe = b.addExecutable(.{
        .name = "zt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zetesis", .module = mod },
                .{ .name = "vaxis", .module = vaxis.module("vaxis") },
            },
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run zt");
    run_step.dependOn(&run_cmd.step);

    const test_module = b.createModule(.{
        .root_source_file = b.path("tests/root.test.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zetesis", .module = mod }},
    });
    const tests = b.addTest(.{ .root_module = test_module });

    const test_step = b.step("test", "Run tests");
    const run_tests = b.addSystemCommand(&.{"env"});
    run_tests.addArtifactArg(tests);
    test_step.dependOn(&run_tests.step);
}
