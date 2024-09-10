const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const fileExists = @import("util.zig").fileExists;

const OS = struct {
    name: []const u8,
    id: []const u8,
};

pub fn osname(allocator: *mem.Allocator) !OS {
    var file: fs.File = undefined;
    var os_id_prefix: []const u8 = undefined;
    var os_name_prefix: []const u8 = undefined;
    var os_name: []const u8 = "generic";
    var os_id: []const u8 = "generic";

    if (fileExists("/etc/lsb-release")) {
        file = try fs.openFileAbsolute(
            "/etc/lsb-release",
            .{ .mode = .read_only },
        );
        os_id_prefix =
            \\DISTRIB_ID=
        ;
        os_name_prefix =
            \\DISTRIB_DESCRIPTION="
        ;
    } else if (fileExists("/etc/os-release")) {
        file = try fs.openFileAbsolute(
            "/etc/os-release",
            .{ .mode = .read_only },
        );
        os_id_prefix =
            \\ID=
        ;
        os_name_prefix =
            \\PRETTY_NAME="
        ;
    }

    const file_read = try file.readToEndAlloc(allocator.*, 0x200);
    file.close();
    defer allocator.free(file_read);

    var lines = mem.tokenize(u8, file_read, "\n");
    while (true) {
        var line = lines.next() orelse break;
        if (mem.startsWith(u8, line, os_name_prefix)) {
            os_name = line[os_name_prefix.len .. line.len - 1];
        }
        if (mem.startsWith(u8, line, os_id_prefix)) {
            os_id = line[os_id_prefix.len..];
        }
    }
    // return &[2][]const u8{ os_name, os_id };

    const res1 = try allocator.dupe(u8, os_name);
    const res2 = try allocator.dupe(u8, os_id);
    errdefer allocator.free(res1); // TODO: potential memory leak here
    errdefer allocator.free(res2);

    return OS{ .name = res1, .id = res2 };
}

pub fn kernel(allocator: *mem.Allocator) ![]const u8 {
    var file: fs.File = undefined;

    if (fileExists("/proc/version")) {
        file = try fs.openFileAbsolute("/proc/version", .{ .mode = .read_only });
    }

    const file_read = try file.readToEndAlloc(allocator.*, 0x100);
    file.close();
    defer allocator.free(file_read);

    var info = mem.tokenize(u8, file_read, " ");
    var kernel_ver: []const u8 = undefined;
    while (true) {
        const word = info.next() orelse break;
        if (mem.eql(u8, word, "version")) {
            kernel_ver = info.next().?;
            break;
        }
    }

    const res = try allocator.dupe(u8, kernel_ver);
    errdefer allocator.free(res);

    return res;
}

pub fn uptime(allocator: *mem.Allocator) ![]const u8 {
    var file: fs.File = undefined;
    var file_read: []const u8 = undefined;
    var uptime_nanos: u64 = undefined;

    if (fileExists("/proc/uptime")) {
        file = try fs.openFileAbsolute("/proc/uptime", .{ .mode = .read_only });
        file_read = try file.readToEndAlloc(allocator.*, 0x40);

        var uptime_data = mem.tokenize(u8, file_read, ".");
        const real_uptime = uptime_data.next().?;
        uptime_nanos =
            (try std.fmt.parseUnsigned(u64, real_uptime, 10)) * 1_000_000_000;
    } else if (fileExists("/proc/stat")) {
        const epoch: u64 = @intCast(@divTrunc(std.time.milliTimestamp(), 1000));
        var btime: []const u8 = undefined;

        file = try fs.openFileAbsolute("/proc/stat", .{ .mode = .read_only });
        file_read = try file.readToEndAlloc(allocator.*, 0x1000);

        var uptime_data = mem.tokenize(u8, file_read, "\n");
        const prefix = "btime ";
        while (true) {
            var line = uptime_data.next() orelse break;
            if (mem.startsWith(u8, line, prefix)) {
                btime = line[prefix.len..];
                uptime_nanos =
                    (epoch - (try std.fmt.parseUnsigned(u64, btime, 10))) * 1_000_000_000;
                break;
            }
        }
    }

    file.close();
    defer allocator.free(file_read);

    const formatted = try std.fmt.allocPrint(
        allocator.*,
        "{}",
        .{std.fmt.fmtDuration(uptime_nanos)},
    );

    defer allocator.free(formatted);

    const res = try allocator.dupe(u8, formatted);
    errdefer allocator.free(res);

    return res;
}
