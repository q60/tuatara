usingnamespace @import("env.zig");

pub fn osName(allocator: *mem.Allocator) ![]const u8 {
    const file = fs.openFileAbsolute("/etc/os-release", .{ .read = true }) catch {
        return "unknown";
    };

    const file_read = try file.readToEndAlloc(allocator, 0x200);
    defer allocator.free(file_read);

    var lines = mem.tokenize(u8, file_read, "\n");
    var os_name: []const u8 = undefined;
    const os_name_prefix =
        \\PRETTY_NAME="
    ;
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
