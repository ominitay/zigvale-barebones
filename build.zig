const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const Arch = std.Target.Cpu.Arch;
const CrossTarget = std.zig.CrossTarget;

const deps = @import("deps.zig");

pub fn build(b: *Builder) !void {
    // const arch = b.option(Arch, "arch", "The CPU architecture to build for") orelse builtin.target.cpu.arch;
    const arch: Arch = .x86_64;
    const target = try genTarget(arch);

    const kernel = try buildKernel(b, target);

    const iso = try buildLimineIso(b, kernel);

    const qemu = try runIsoQemu(b, iso, arch);
    _ = qemu;
}

fn genTarget(arch: std.Target.Cpu.Arch) !CrossTarget {
    var target = CrossTarget{ .cpu_arch = arch, .os_tag = .freestanding, .abi = .none };

    switch (arch) {
        .x86_64 => {
            const features = std.Target.x86.Feature;
            target.cpu_features_sub.addFeature(@enumToInt(features.mmx));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse));
            target.cpu_features_sub.addFeature(@enumToInt(features.sse2));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx));
            target.cpu_features_sub.addFeature(@enumToInt(features.avx2));

            target.cpu_features_add.addFeature(@enumToInt(features.soft_float));
        },

        else => return error.UnsupportedArchitecture,
    }

    return target;
}

fn buildKernel(b: *Builder, target: CrossTarget) !*std.build.LibExeObjStep {
    const mode = b.standardReleaseOptions();
    const kernel = b.addExecutable("kernel", "src/kernel.zig");

    kernel.setTarget(target);
    kernel.code_model = switch (target.cpu_arch.?) {
        .x86_64 => .kernel,
        .aarch64 => .small,
        else => return error.UnsupportedArchitecture,
    };

    kernel.setBuildMode(mode);
    deps.addAllTo(kernel);
    kernel.setLinkerScriptPath(.{ .path = "src/linker.ld" });
    kernel.install();

    return kernel;
}

fn buildLimineIso(b: *Builder, kernel: *std.build.LibExeObjStep) !*std.build.RunStep {
    const limine_install_executable = switch (builtin.os.tag) {
        .linux => "limine-install-linux-x86_64",
        .windows => "limine-install-win32.exe",
        else => return error.UnsupportedOs,
    };
    const mkiso_args = &[_][]const u8{
        "./mkiso.sh",
        "zig-out/bin/kernel",
        "src/limine",
        "zig-out/iso/root",
        "zig-out/iso/zigvale-barebones.iso",
        deps.package_data._limine.directory,
        limine_install_executable,
    };

    const iso_cmd = b.addSystemCommand(mkiso_args);
    iso_cmd.step.dependOn(&kernel.install_step.?.step);

    const iso_step = b.step("iso", "Generate bootable ISO file");
    iso_step.dependOn(&iso_cmd.step);

    return iso_cmd;
}

fn runIsoQemu(b: *Builder, iso: *std.build.RunStep, arch: Arch) !*std.build.RunStep {
    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        else => return error.UnsupportedArchitecture,
    };
    const qemu_iso_args = &[_][]const u8{
        qemu_executable,
        "-cdrom",
        "zig-out/iso/zigvale-barebones.iso",
    };
    const qemu_iso_cmd = b.addSystemCommand(qemu_iso_args);
    qemu_iso_cmd.step.dependOn(&iso.step);

    const qemu_iso_step = b.step("run", "Boot ISO in qemu");
    qemu_iso_step.dependOn(&qemu_iso_cmd.step);

    return qemu_iso_cmd;
}
