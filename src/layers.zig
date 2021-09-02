usingnamespace @import("env.zig");
const fileExists = @import("util.zig").fileExists;

pub fn osname(allocator: *mem.Allocator) ![]const u8 {
    var file: fs.File = undefined;
    var os_name_prefix: []const u8 = undefined;

    if (fileExists("/etc/lsb-release")) {
        file = try fs.openFileAbsolute("/etc/lsb-release", .{ .read = true });
        os_name_prefix =
            \\DISTRIB_DESCRIPTION="
        ;
    } else if (fileExists("/etc/os-release")) {
        file = try fs.openFileAbsolute("/etc/os-release", .{ .read = true });
        os_name_prefix =
            \\PRETTY_NAME="
        ;
    }

    const file_read = try file.readToEndAlloc(allocator, 0x200);
    file.close();
    defer allocator.free(file_read);

    var lines = mem.tokenize(u8, file_read, "\n");
    var os_name: []const u8 = undefined;
    while (true) {
        var line = lines.next() orelse break;
        if (mem.startsWith(u8, line, os_name_prefix)) {
            os_name = line[os_name_prefix.len .. line.len - 1];
            break;
        }
    }

    const res = try allocator.dupe(u8, os_name);
    errdefer allocator.free(res);

    return res;
}

pub fn kernel(allocator: *mem.Allocator) ![]const u8 {
    var file: fs.File = undefined;

    if (fileExists("/proc/version")) {
        file = try fs.openFileAbsolute("/proc/version", .{ .read = true });
    }

    const file_read = try file.readToEndAlloc(allocator, 0x100);
    file.close();
    defer allocator.free(file_read);

    var info = mem.tokenize(u8, file_read, " ");
    var kernel_ver: []const u8 = undefined;
    while (true) {
        var word = info.next() orelse break;
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
        file = try fs.openFileAbsolute("/proc/uptime", .{ .read = true });
        file_read = try file.readToEndAlloc(allocator, 0x40);

        var uptime_data = mem.tokenize(u8, file_read, ".");
        const real_uptime = uptime_data.next().?;
        uptime_nanos =
            (try std.fmt.parseUnsigned(u64, real_uptime, 10)) * 1_000_000_000;
    } else if (fileExists("/proc/stat")) {
        const epoch = @intCast(u64, @divTrunc(std.time.milliTimestamp(), 1000));
        var btime: []const u8 = undefined;

        file = try fs.openFileAbsolute("/proc/stat", .{ .read = true });
        file_read = try file.readToEndAlloc(allocator, 0x1000);

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
        allocator,
        "{}",
        .{std.fmt.fmtDuration(uptime_nanos)},
    );
    defer allocator.free(formatted);

    const res = try allocator.dupe(u8, formatted);
    errdefer allocator.free(res);

    return res;
}
