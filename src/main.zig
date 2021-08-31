usingnamespace @import("env.zig");

const layers = @import("layers.zig");
const builtin = @import("builtin");
const List = std.ArrayList;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = &gpa.allocator;
    defer {
        _ = gpa.deinit();
    }

    var info = List([][]const u8).init(alloc);
    defer info.deinit();

    var home = mem.tokenize(u8, os.getenv("HOME").?, fs.path.sep_str);
    var username: []const u8 = undefined;
    while (true) {
        username = home.next() orelse break;
    }

    var buf: [os.HOST_NAME_MAX]u8 = undefined;
    const hostname = try os.gethostname(&buf);

    const os_name = try layers.osName(alloc);
    defer alloc.free(os_name);
    try info.append(&[_][]const u8{ os_name, "[os]" });

    const arch = builtin.cpu.arch;
    try info.append(&[_][]const u8{ std.meta.tagName(arch), "[arch]" });

    print("{s:>11} @ {s}\n", .{ username, hostname });
    for (info.items) |layer| {
        print("{s:>12} ", .{layer[0]});
        print("{s}\n", .{layer[1]});
    }
}
