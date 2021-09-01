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

    const res = try allocator.alloc(u8, os_name.len);
    errdefer allocator.free(res);

    mem.copy(u8, res, os_name);
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

    const res = try allocator.alloc(u8, kernel_ver.len);
    errdefer allocator.free(res);

    mem.copy(u8, res, kernel_ver);
    return res;
}

pub fn uptime(allocator: *mem.Allocator) ![]const u8 {
    const c = @cImport({
        @cInclude("sys/sysinfo.h");
    });

    var info: c.struct_sysinfo = undefined;
    _ = c.sysinfo(&info);

    var uptime_nanos: u64 = @bitCast(u64, info.uptime) * 1_000_000_000;

    const formatted = try std.fmt.allocPrint(
        allocator,
        "{}",
        .{std.fmt.fmtDuration(uptime_nanos)},
    );
    defer allocator.free(formatted);

    const res = try allocator.alloc(u8, formatted.len);
    errdefer allocator.free(res);

    mem.copy(u8, res, formatted);
    return res;
}
