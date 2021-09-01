usingnamespace @import("env.zig");

const layers = @import("layers.zig");
const indented = @import("util.zig").rightAlign;
const builtin = @import("builtin");

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

    const os_name = try layers.osname(alloc);
    defer alloc.free(os_name);

    const os_name_upper = try std.ascii.allocUpperString(alloc, os_name);
    defer alloc.free(os_name_upper);
    try info.append(&[_][]const u8{ os_name_upper, "[os]" });

    const kernel_ver = try layers.kernel(alloc);
    defer alloc.free(kernel_ver);
    try info.append(&[_][]const u8{ kernel_ver, "[kernel]" });

    const arch = builtin.cpu.arch;
    try info.append(&[_][]const u8{ std.meta.tagName(arch), "[arch]" });

    const uptime = try layers.uptime(alloc);
    defer alloc.free(uptime);
    try info.append(&[_][]const u8{ uptime, "[uptime]" });

    var max_length: usize = 0;
    for (info.items) |layer| {
        var current_len = layer[0].len;
        if (current_len > max_length) {
            max_length = layer[0].len;
        }
    }

    const user_indent = try indented(alloc, max_length - username.len + 1);
    defer alloc.free(user_indent);

    print("{s}{s} @ {s}\n", .{ user_indent, username, hostname });
    for (info.items) |layer| {
        const layer_indent = try indented(alloc, max_length - layer[0].len + 1);
        defer alloc.free(layer_indent);
        print("{s}{s} | ", .{ layer_indent, layer[0] });
        print("{s}\n", .{layer[1]});
    }
}
