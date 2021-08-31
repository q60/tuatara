usingnamespace @import("env.zig");

pub fn fileExists(absolute_path: []const u8) bool {
    const file = fs.openFileAbsolute(absolute_path, .{ .read = true }) catch {
        return false;
    };
    file.close();
    return true;
}

pub fn rightAlign(allocator: *mem.Allocator, maxlen: usize) ![]const u8 {
    var indent = List(u8).init(allocator);
    defer indent.deinit();

    var i: usize = 0;
    while (i <= maxlen) : (i += 1) {
        try indent.append(0x20);
    }

    return indent.toOwnedSlice();
}
