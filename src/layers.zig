usingnamespace @import("env.zig");
const fileExists = @import("util.zig").fileExists;

pub fn osname(allocator: *mem.Allocator) ![]const u8 {
    var file: fs.File = undefined;
    var os_name_prefix: []const u8 = undefined;

    if (fileExists("/etc/lsb-release")) {
        file = fs.openFileAbsolute("/etc/lsb-release", .{ .read = true }) catch unreachable;
        os_name_prefix =
            \\DISTRIB_DESCRIPTION="
        ;
    } else if (fileExists("/etc/os-release")) {
        file = fs.openFileAbsolute("/etc/os-release", .{ .read = true }) catch unreachable;
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
