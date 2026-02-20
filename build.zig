const std = @import("std");

const common_sources = &.{
    "core.c",
    "descriptor.c",
    "hotplug.c",
    "io.c",
    "strerror.c",
    "sync.c",
};

const posix_platform_sources = &.{
    "events_posix.c",
    "threads_posix.c",
};

const windows_platform_sources = &.{
    "events_windows.c",
    "threads_windows.c",
};

fn defineFromBool(value: bool) ?u1 {
    return if (value) 1 else null;
}

const ConfigureOptions = struct {
    enable_udev: bool,
    enable_eventfd: bool,
    enable_timerfd: bool,
    enable_logging: bool,
    enable_syslog: bool,
};

fn configureLibusb(
    dep: *std.Build.Dependency,
    module: *std.Build.Module,
    config_header: *std.Build.Step.ConfigHeader,
    options: ConfigureOptions,
) void {
    const target = module.resolved_target.?.result;
    const is_posix = target.os.tag != .windows;

    module.link_libc = true;
    module.addIncludePath(dep.path("libusb"));

    if (target.os.tag.isDarwin()) {
        module.addIncludePath(dep.path("Xcode"));
    } else if (target.abi == .msvc) {
        module.addIncludePath(dep.path("msvc"));
    } else if (target.abi == .android) {
        module.addIncludePath(dep.path("android"));
    } else {
        module.addConfigHeader(config_header);
    }

    module.addCSourceFiles(.{
        .root = dep.path("libusb"),
        .files = common_sources,
    });

    module.addCSourceFiles(.{
        .root = dep.path("libusb/os"),
        .files = if (is_posix) posix_platform_sources else windows_platform_sources,
    });

    if (target.os.tag.isDarwin()) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{"darwin_usb.c"},
        });
        module.linkFramework("IOKit", .{});
        module.linkFramework("CoreFoundation", .{});
        module.linkFramework("Security", .{});
    } else if (target.os.tag == .linux) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{
                "linux_usbfs.c",
                if (options.enable_udev) "linux_udev.c" else "linux_netlink.c",
            },
        });
        if (options.enable_udev) {
            module.linkSystemLibrary("udev", .{});
        }
    } else if (target.os.tag == .windows) {
        module.addWin32ResourceFile(.{ .file = dep.path("libusb/libusb-1.0.rc") });
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{
                "windows_common.c",
                "windows_usbdk.c",
                "windows_winusb.c",
            },
        });
    } else if (target.os.tag == .netbsd) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{"netbsd_usb.c"},
        });
    } else if (target.os.tag == .openbsd) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{"openbsd_usb.c"},
        });
    } else if (target.os.tag == .haiku) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{
                "haiku_pollfs.cpp",
                "haiku_usb_backend.cpp",
                "haiku_usb_raw.cpp",
            },
        });
        module.linkSystemLibrary("be", .{});
    } else if (target.os.tag == .solaris) {
        module.addCSourceFiles(.{
            .root = dep.path("libusb/os"),
            .files = &.{"sunos_usb.cpp"},
        });
        module.linkSystemLibrary("devinfo", .{});
    }
}

fn addLibrary(
    b: *std.Build,
    dep: *std.Build.Dependency,
    linkage: std.builtin.LinkMode,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    config_header: *std.Build.Step.ConfigHeader,
    options: ConfigureOptions,
) void {
    const lib = b.addLibrary(.{
        .name = "usb",
        .version = .{ .major = 1, .minor = 0, .patch = 29 },
        .linkage = linkage,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    configureLibusb(dep, lib.root_module, config_header, options);
    lib.installHeader(dep.path("libusb/libusb.h"), "libusb.h");
    b.installArtifact(lib);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("libusb", .{});

    const build_static = b.option(bool, "static", "Build static lib (default: true)") orelse true;
    const build_shared = b.option(bool, "shared", "Build shared lib (default: true)") orelse true;
    const enable_udev = b.option(bool, "enable_udev", "Use udev for device enumeration and hotplug support (default: false)") orelse false;
    const enable_eventfd = b.option(bool, "enable_eventfd", "Use eventfd for signaling (default: false)") orelse false;
    const enable_timerfd = b.option(bool, "enable_timerfd", "Use timerfd for timing (default: false)") orelse false;
    const disable_log = b.option(bool, "disable_log", "Disable all logging (default: false)") orelse false;
    const enable_syslog = b.option(bool, "enable_system_log", "Output logs to the system-wide log when supported (default: false)") orelse false;

    const options = ConfigureOptions{
        .enable_udev = enable_udev,
        .enable_eventfd = enable_eventfd,
        .enable_timerfd = enable_timerfd,
        .enable_logging = !disable_log,
        .enable_syslog = enable_syslog,
    };

    const config_header = b.addConfigHeader(.{ .style = .blank }, .{
        ._GNU_SOURCE = 1,
        .DEFAULT_VISIBILITY = .@"__attribute__ ((visibility (\"default\")))",
        .@"PRINTF_FORMAT(a, b)" = .@"/* */",
        .PLATFORM_POSIX = defineFromBool(target.result.os.tag != .windows),
        .PLATFORM_WINDOWS = defineFromBool(target.result.os.tag == .windows),
        .HAVE_EVENTFD = defineFromBool(options.enable_eventfd),
        .HAVE_TIMERFD = defineFromBool(options.enable_timerfd),
        .HAVE_CLOCK_GETTIME = defineFromBool(target.result.os.tag != .windows),
        .ENABLE_LOGGING = defineFromBool(options.enable_logging),
        .USE_SYSTEM_LOGGING_FACILITY = defineFromBool(options.enable_syslog),
    });

    if (build_static) addLibrary(b, dep, .static, target, optimize, config_header, options);
    if (build_shared) addLibrary(b, dep, .dynamic, target, optimize, config_header, options);

    const libusb_module = b.addModule("libusb", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    configureLibusb(dep, libusb_module, config_header, options);

    const lib_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    configureLibusb(dep, lib_unit_tests.root_module, config_header, options);

    const run_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // Add a run step for an example program, to test it out
    // Unit testing is hard, because we can't control what the attached USB stuff is...

    const exe = b.addExecutable(.{
        .name = "zig_libusb_example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "libusb", .module = libusb_module },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    // Pass through CLI arguments: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
