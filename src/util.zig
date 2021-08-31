usingnamespace @import("env.zig");

pub fn fileExists(absolute_path: []const u8) bool {
    _ = fs.openFileAbsolute(absolute_path, .{ .read = true }) catch {
        return false;
    };
    return true;
}
