usingnamespace @import("env.zig");

const builtin = @import("builtin");
const layers = @import("layers.zig");
const indented = @import("util.zig").rightAlign;
const getlogo = @import("logos.zig").getlogo;
const res = @import("resources.zig");
const Args = res.Args;
const OsEnum = res.OsEnum;

fn parseArgs(allocator: *mem.Allocator) !Args {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var parsed = Args{
        .colors = true,
        .help = false,
        .layer_names = true,
        .logo = null,
    };

    for (args) |arg, i| {
        const arg_word = std.mem.trim(u8, arg, "-");

        //* Boolean options
        // monochrome mode
        if (mem.eql(u8, arg_word, "mono") or mem.eql(u8, arg_word, "m")) {
            parsed.colors = false;
        }

        // display help message
        if (mem.eql(u8, arg_word, "help") or mem.eql(u8, arg_word, "h")) {
            parsed.help = true;
        }

        // disable layer names
        if (mem.eql(u8, arg_word, "no-names") or mem.eql(u8, arg_word, "nn")) {
            parsed.layer_names = false;
        }

        //* 1-arity options
        // choose between OS logos
        if (mem.eql(u8, arg_word, "logo") or mem.eql(u8, arg_word, "l")) {
            const os_id = try std.ascii.allocLowerString(allocator, args[i + 1]);
            defer allocator.free(os_id);

            parsed.logo = std.meta.stringToEnum(OsEnum, os_id) orelse OsEnum.generic;
        }
    }
    return parsed;
}

fn help(colorset: res.Colors) !void {
    const ansi = colorset;
    try print(
        \\{s}tuatara is a CLI system information tool written in Zig{s}
        \\
        \\{s}syntax:{s}
        \\    tuatara {s}[options]{s}
        \\{s}options:{s}
        \\    {s}-h,  --help{s}        {s}prints this message{s}
        \\    {s}-l,  --logo{s}        {s}sets distro logo to print{s}
        \\    {s}-m,  --mono{s}        {s}enables monochrome mode{s}
        \\    {s}-nn, --no-names{s}    {s}disables layer names{s}
        \\
    ,
        .{
            ansi.yy, ansi.x, ansi.z,  ansi.x,
            ansi.gg, ansi.x, ansi.z,  ansi.x,
            ansi.gg, ansi.x, ansi.yy, ansi.x,
            ansi.gg, ansi.x, ansi.yy, ansi.x,
            ansi.gg, ansi.x, ansi.yy, ansi.x,
            ansi.gg, ansi.x, ansi.yy, ansi.x,
        },
    );
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = &GPA.allocator;
    defer {
        _ = GPA.deinit();
    }

    var ansi: res.Colors = res.ansi;

    // argv
    const args = try parseArgs(gpa);
    if (!args.colors) {
        ansi = res.mono;
    }
    if (args.help) {
        try help(ansi);
        return;
    }

    // layers list
    var info = List([]const []const u8).init(gpa);
    defer {
        for (info.items) |item| {
            for (item) |v| {
                gpa.free(v);
            }
        }
        info.deinit();
    }
    const layer_names = if (args.layer_names)
        [7][]const u8{
            " | [os]",      " | [kernel]",
            " | [arch]",    " | [uptime]",
            " | [shell]",   " | [editor]",
            " | [browser]",
        }
    else
        [7][]const u8{
            " |", " |",
            " |", " |",
            " |", " |",
            " |",
        };

    // user@host layer
    var home = mem.tokenize(u8, os.getenv("HOME").?, fs.path.sep_str);
    var username: []const u8 = undefined;
    while (true) {
        username = home.next() orelse break;
    }
    var buf: [os.HOST_NAME_MAX]u8 = undefined;
    const hostname = try os.gethostname(&buf);

    // OS layer
    const os_struct = layers.osname(gpa);
    var logo: [8][]const u8 = undefined;
    var motif: []const u8 = undefined;
    defer for (logo) |line| {
        gpa.free(line);
    };

    if (os_struct) |os_name| {
        defer gpa.free(os_name.id);
        defer gpa.free(os_name.name);
        const os_name_upper = try std.ascii.allocUpperString(gpa, os_name.name);

        try info.append(&[_][]const u8{
            os_name_upper,
            try gpa.dupe(u8, layer_names[0]),
        });

        var logo_struct: res.Logo = undefined;

        if (args.logo == null) {
            const os_id = try std.ascii.allocLowerString(gpa, os_name.id);
            defer gpa.free(os_id);
            logo_struct = try getlogo(gpa, os_id, ansi);
        } else {
            logo_struct = try getlogo(gpa, args.logo, ansi);
        }
        logo = logo_struct.logo;
        motif = logo_struct.motif;
    } else |_| {}

    // kernel layer
    if (layers.kernel(gpa)) |kernel_ver| {
        defer gpa.free(kernel_ver);
        const kernel_ver_upper = try std.ascii.allocUpperString(gpa, kernel_ver);
        try info.append(&[_][]const u8{
            kernel_ver_upper,
            try gpa.dupe(u8, layer_names[1]),
        });
    } else |_| {}

    // arch layer
    const arch = std.meta.tagName(builtin.cpu.arch);
    const arch_upper = try std.ascii.allocUpperString(gpa, arch);
    try info.append(&[_][]const u8{
        arch_upper,
        try gpa.dupe(u8, layer_names[2]),
    });

    // uptime layer
    if (layers.uptime(gpa)) |uptime| {
        defer gpa.free(uptime);
        const uptime_upper = try std.ascii.allocUpperString(gpa, uptime);
        try info.append(&[_][]const u8{
            uptime_upper,
            try gpa.dupe(u8, layer_names[3]),
        });
    } else |_| {}

    // shell layer
    const shell_env = os.getenv("SHELL");
    if (shell_env) |shell_exists| {
        var shell = mem.tokenize(u8, shell_exists, fs.path.sep_str);
        var shell_bin: []const u8 = undefined;
        while (true) {
            shell_bin = shell.next() orelse break;
        }
        const shell_upper = try std.ascii.allocUpperString(gpa, shell_bin);
        try info.append(&[_][]const u8{
            shell_upper,
            try gpa.dupe(u8, layer_names[4]),
        });
    }

    // editor layer
    const editor_env = os.getenv("EDITOR");
    if (editor_env) |editor_exists| {
        var editor = mem.tokenize(u8, editor_exists, fs.path.sep_str);
        var editor_bin: []const u8 = undefined;
        while (true) {
            editor_bin = editor.next() orelse break;
        }
        const editor_upper = try std.ascii.allocUpperString(gpa, editor_bin);
        try info.append(&[_][]const u8{
            editor_upper,
            try gpa.dupe(u8, layer_names[5]),
        });
    }

    // browser layer
    const browser_env = os.getenv("BROWSER");
    if (browser_env) |browser_exists| {
        var browser = mem.tokenize(u8, browser_exists, fs.path.sep_str);
        var browser_bin: []const u8 = undefined;
        while (true) {
            browser_bin = browser.next() orelse break;
        }
        const browser_upper = try std.ascii.allocUpperString(gpa, browser_bin);
        try info.append(&[_][]const u8{
            browser_upper,
            try gpa.dupe(u8, layer_names[6]),
        });
    }

    // getting length of the longest layer
    var max_length: usize = 0;
    for (info.items) |layer| {
        var current_len = layer[0].len;
        if (current_len > max_length) {
            max_length = layer[0].len;
        }
    }

    // try print out user@host
    const user_indent = try indented(gpa, max_length - username.len + 1);
    defer gpa.free(user_indent);
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
            const layer_indent = try indented(gpa, max_length - info_layer.len + 1);
            defer gpa.free(layer_indent);
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
