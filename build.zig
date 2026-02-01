const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "grincel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // System libraries
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("objc");

    // Platform specific libraries
    if (target.result.os.tag == .macos) {
        exe.addFrameworkPath(.{ .cwd_relative = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks" });
        exe.addSystemIncludePath(.{ .cwd_relative = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include" });
        exe.linkFramework("Metal");
        exe.linkFramework("Foundation");
        exe.linkFramework("QuartzCore");
        
        // Add Objective-C bridge
        exe.addCSourceFile(.{
            .file = b.path("src/metal_bridge.m"),
            .flags = &.{"-fobjc-arc"},
        });
        exe.addIncludePath(b.path("src"));
    } else {
        exe.linkSystemLibrary("vulkan");
    }

    exe.addIncludePath(b.path("deps/ed25519/src"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the vanity address generator");
    run_step.dependOn(&run_cmd.step);
}
