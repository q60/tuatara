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

    // layers list
    var info = List([][]const u8).init(alloc);
    defer info.deinit();

    // temporary solution
    const blue = "\x1B[34m\x1B[1m";
    const br_blue = "\x1B[94m\x1B[1m";
    const reset = "\x1B[0m";
    const bold = "\x1B[1m";

    // user@host layer
    var home = mem.tokenize(u8, os.getenv("HOME").?, fs.path.sep_str);
    var username: []const u8 = undefined;
    while (true) {
        username = home.next() orelse break;
    }
    var buf: [os.HOST_NAME_MAX]u8 = undefined;
    const hostname = try os.gethostname(&buf);

    // OS layer
    const os_name = try layers.osname(alloc);
    defer alloc.free(os_name);
    const os_name_upper = try std.ascii.allocUpperString(alloc, os_name);
    defer alloc.free(os_name_upper);
    try info.append(&[_][]const u8{ os_name_upper, "[os]" });

    // kernel layer
    const kernel_ver = try layers.kernel(alloc);
    defer alloc.free(kernel_ver);
    const kernel_ver_upper = try std.ascii.allocUpperString(alloc, kernel_ver);
    defer alloc.free(kernel_ver_upper);
    try info.append(&[_][]const u8{ kernel_ver_upper, "[kernel]" });

    // arch layer
    const arch = std.meta.tagName(builtin.cpu.arch);
    const arch_upper = try std.ascii.allocUpperString(alloc, arch);
    defer alloc.free(arch_upper);
    try info.append(&[_][]const u8{ arch_upper, "[arch]" });

    // uptime layer
    const uptime = try layers.uptime(alloc);
    defer alloc.free(uptime);
    const uptime_upper = try std.ascii.allocUpperString(alloc, uptime);
    defer alloc.free(uptime_upper);
    try info.append(&[_][]const u8{ uptime_upper, "[uptime]" });

    // getting length of the longest layer
    var max_length: usize = 0;
    for (info.items) |layer| {
        var current_len = layer[0].len;
        if (current_len > max_length) {
            max_length = layer[0].len;
        }
    }

    // print out user@host
    const user_indent = try indented(alloc, max_length - username.len + 1);
    defer alloc.free(user_indent);
    print("{s}{s}{s}{s} @ {s}{s}{s}\n", .{ user_indent, blue, username, reset, blue, hostname, reset });

    // print layers
    for (info.items) |layer| {
        const layer_indent = try indented(alloc, max_length - layer[0].len + 1);
        defer alloc.free(layer_indent);
        print("{s}{s} {s}|{s} ", .{ layer_indent, layer[0], bold, reset });
        print("{s}{s}{s}\n", .{ br_blue, layer[1], reset });
    }
}
