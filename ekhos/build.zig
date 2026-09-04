const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const renderer = b.addExecutable(.{
        .name = "ekhos-render",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(renderer);

    const render = b.addRunArtifact(renderer);

    const render_step = b.step("render", "Render the Ekhos sound palette");
    render_step.dependOn(&render.step);
    b.getInstallStep().dependOn(&render.step);
}
