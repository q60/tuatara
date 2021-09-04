usingnamespace @import("env.zig");

const builtin = @import("builtin");
const layers = @import("layers.zig");
const indented = @import("util.zig").rightAlign;
const ansi = @import("resources.zig").ansi;
const getlogo = @import("logo.zig").getlogo;

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
            for (item) |v| {
                alloc.free(v);
            }
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
    const os_struct = layers.osname(alloc);
    var logo: [8][]const u8 = undefined;
    var motif: []const u8 = undefined;
    defer for (logo) |line| {
        alloc.free(line);
    };

    if (os_struct) |os_name| {
        defer alloc.free(os_name.id);
        defer alloc.free(os_name.name);
        const os_name_upper = try std.ascii.allocUpperString(alloc, os_name.name);

        try info.append(&[_][]const u8{
            os_name_upper,
            try alloc.dupe(u8, " | [os]"),
        });
        const os_id = try std.ascii.allocLowerString(alloc, os_name.id);
        defer alloc.free(os_id);

        const logo_struct = try getlogo(alloc, os_id);
        logo = logo_struct.logo;
        motif = logo_struct.motif;
    } else |_| {}

    // kernel layer
    if (layers.kernel(alloc)) |kernel_ver| {
        defer alloc.free(kernel_ver);
        const kernel_ver_upper = try std.ascii.allocUpperString(alloc, kernel_ver);
        try info.append(&[_][]const u8{
            kernel_ver_upper,
            try alloc.dupe(u8, " | [kernel]"),
        });
    } else |_| {}

    // arch layer
    const arch = std.meta.tagName(builtin.cpu.arch);
    const arch_upper = try std.ascii.allocUpperString(alloc, arch);
    try info.append(&[_][]const u8{
        arch_upper,
        try alloc.dupe(u8, " | [arch]"),
    });

    // uptime layer
    if (layers.uptime(alloc)) |uptime| {
        defer alloc.free(uptime);
        const uptime_upper = try std.ascii.allocUpperString(alloc, uptime);
        try info.append(&[_][]const u8{
            uptime_upper,
            try alloc.dupe(u8, " | [uptime]"),
        });
    } else |_| {}

    // editor layer
    var editor = mem.tokenize(u8, os.getenv("EDITOR").?, fs.path.sep_str);
    var editor_bin: []const u8 = undefined;
    while (true) {
        editor_bin = editor.next() orelse break;
    }
    const editor_upper = try std.ascii.allocUpperString(alloc, editor_bin);
    try info.append(&[_][]const u8{
        editor_upper,
        try alloc.dupe(u8, " | [editor]"),
    });

    // browser layer
    var browser = mem.tokenize(u8, os.getenv("BROWSER").?, fs.path.sep_str);
    var browser_bin: []const u8 = undefined;
    while (true) {
        browser_bin = browser.next() orelse break;
    }
    const browser_upper = try std.ascii.allocUpperString(alloc, browser_bin);
    try info.append(&[_][]const u8{
        browser_upper,
        try alloc.dupe(u8, " | [browser]"),
    });

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
    try print("  {s}", .{
        logo[0],
    });
    try print("{s}{s}{s}{s}{s} @ {s}{s}{s}{s}\n", .{
        user_indent, motif,
        ansi.z,      username,
        ansi.x,      motif,
        ansi.z,      hostname,
        ansi.x,
    });

    // try print layers
    for (logo[1..]) |logo_line, index| {
        try print("  {s}", .{
            logo_line,
        });
        if (index < (info.items.len)) {
            const info_layer = info.items[index][0];
            const layer_name = info.items[index][1];
            const layer_indent = try indented(alloc, max_length - info_layer.len + 1);
            defer alloc.free(layer_indent);
            try print("{s}{s}", .{
                layer_indent,
                info_layer,
            });
            try print("{s}{s}{s}{s}\n", .{
                motif,      ansi.z,
                layer_name, ansi.x,
            });
        } else {
            try print("\n", .{});
        }
    }
}
