usingnamespace @import("env.zig");

const layers = @import("layers.zig");
const indented = @import("util.zig").rightAlign;
const builtin = @import("builtin");
const ansi = @import("resources.zig").ansi;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = &gpa.allocator;
    defer {
        _ = gpa.deinit();
    }

    // layers list
    var info = List([]const []const u8).init(alloc);
    defer {
        for (info.items) |item| {
            for (item) |v|
                alloc.free(v);
        }
        info.deinit();
    }

    // user@host layer
    var home = mem.tokenize(u8, os.getenv("HOME").?, fs.path.sep_str);
    var username: []const u8 = undefined;
    while (true) {
        username = home.next() orelse break;
    }
    var buf: [os.HOST_NAME_MAX]u8 = undefined;
    const hostname = try os.gethostname(&buf);

    // OS layer
    if (layers.osname(alloc)) |os_name| {
        defer alloc.free(os_name);
        const os_name_upper = try std.ascii.allocUpperString(alloc, os_name);
        try info.append(&[_][]const u8{
            os_name_upper,
            try alloc.dupe(u8, "[os]"),
        });
    } else |_| {}

    // kernel layer
    if (layers.kernel(alloc)) |kernel_ver| {
        defer alloc.free(kernel_ver);
        const kernel_ver_upper = try std.ascii.allocUpperString(alloc, kernel_ver);
        try info.append(&[_][]const u8{
            kernel_ver_upper,
            try alloc.dupe(u8, "[kernel]"),
        });
    } else |_| {}

    // arch layer
    const arch = std.meta.tagName(builtin.cpu.arch);
    const arch_upper = try std.ascii.allocUpperString(alloc, arch);
    try info.append(&[_][]const u8{
        arch_upper,
        try alloc.dupe(u8, "[arch]"),
    });

    // uptime layer
    if (layers.uptime(alloc)) |uptime| {
        defer alloc.free(uptime);
        const uptime_upper = try std.ascii.allocUpperString(alloc, uptime);
        try info.append(&[_][]const u8{
            uptime_upper,
            try alloc.dupe(u8, "[uptime]"),
        });
    } else |_| {}

    // getting length of the longest layer
    var max_length: usize = 0;
    for (info.items) |layer| {
        var current_len = layer[0].len;
        if (current_len > max_length) {
            max_length = layer[0].len;
        }
    }

    // try print out user@host
    const user_indent = try indented(alloc, max_length - username.len + 1);
    defer alloc.free(user_indent);
    try print("{s}{s}{s}{s} @ {s}{s}{s}\n", .{
        user_indent,
        ansi.b ++ ansi.z,
        username,
        ansi.x,
        ansi.b ++ ansi.z,
        hostname,
        ansi.x,
    });

    // try print layers
    for (info.items) |layer| {
        const layer_indent = try indented(alloc, max_length - layer[0].len + 1);

        defer alloc.free(layer_indent);
        try print("{s}{s} {s}|{s} ", .{
            layer_indent,
            layer[0],
            ansi.z,
            ansi.x,
        });
        try print("{s}{s}{s}\n", .{
            ansi.bb ++ ansi.z,
            layer[1],
            ansi.x,
        });
    }
}
