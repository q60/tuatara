usingnamespace @import("env.zig");

const res = @import("resources.zig");
const Logo = res.Logo;
const ansi = res.ansi;
const OsEnum = res.OsEnum;

pub fn getlogo(allocator: *mem.Allocator, os_id: []const u8) !Logo {
    const logo = switch (std.meta.stringToEnum(OsEnum, os_id) orelse OsEnum.generic) {
        .artix => Logo{
            .motif = ansi.b,
            .logo = [8][]const u8{
                try std.fmt.allocPrint( // 0
                    allocator,
                    "       {s}.{s}       ",
                    .{ ansi.b, ansi.x },
                ),
                try std.fmt.allocPrint( // 1
                    allocator,
                    "      {s}/{s}{s}#\\{s}      ",
                    .{ ansi.b, ansi.bb, ansi.z, ansi.x },
                ),
                try std.fmt.allocPrint( // 2
                    allocator,
                    "     {s}/,{s}{s}+,\\{s}     ",
                    .{
                        ansi.b, ansi.bb,
                        ansi.z, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 3
                    allocator,
                    "      {s}`<{s}{s}n,\\{s}    ",
                    .{
                        ansi.b, ansi.bb,
                        ansi.z, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 4
                    allocator,
                    "   {s}{s}/{s}{s},    {s}`{s}{s},\\{s}   ",
                    .{
                        ansi.bb, ansi.z,
                        ansi.x,  ansi.b,
                        ansi.b,  ansi.bb,
                        ansi.z,  ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 5
                    allocator,
                    "  {s}{s}/,hK{s}{s}+>    {s},{s}  ",
                    .{
                        ansi.bb, ansi.z,
                        ansi.x,  ansi.b,
                        ansi.b,  ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 6
                    allocator,
                    " {s}{s}/.b{s}{s}>`    {s}<H{s}{s}.\\{s} ",
                    .{
                        ansi.bb, ansi.z,
                        ansi.x,  ansi.b,
                        ansi.b,  ansi.bb,
                        ansi.z,  ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 7
                    allocator,
                    "{s}{s}/{s}{s}>`         {s}`<{s}{s}\\{s}",
                    .{
                        ansi.bb, ansi.z,
                        ansi.x,  ansi.b,
                        ansi.b,  ansi.bb,
                        ansi.z,  ansi.x,
                    },
                ),
            },
        },

        else => Logo{
            .motif = ansi.yy,
            .logo = [8][]const u8{
                try std.fmt.allocPrint( // 0
                    allocator,
                    "      {s}XXXX{s}      ",
                    .{ ansi.dd, ansi.x },
                ),
                try std.fmt.allocPrint( // 1
                    allocator,
                    "     {s}X{s}{s}^{s}{s}XX{s}{s}^{s}{s}X{s}     ",
                    .{
                        ansi.dd, ansi.x,
                        ansi.z,  ansi.x,
                        ansi.dd, ansi.x,
                        ansi.z,  ansi.x,
                        ansi.dd, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 2
                    allocator,
                    "     {s}X{s}{s}<XX>{s}{s}X{s}     ",
                    .{
                        ansi.dd, ansi.x,
                        ansi.y,  ansi.x,
                        ansi.dd, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 3
                    allocator,
                    "   {s}XX{s}X{s}XXXX{s}X{s}XX{s}   ",
                    .{
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 4
                    allocator,
                    "  {s}XX{s}XXXXXXXX{s}XX{s}  ",
                    .{
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 5
                    allocator,
                    " {s}XX{s}XXXXXXXXXX{s}XX{s} ",
                    .{
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 6
                    allocator,
                    "{s}I{s}{s}XXX{s}XXXXXXXX{s}XXX{s}{s}I{s}",
                    .{
                        ansi.y,  ansi.x,
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                        ansi.y,  ansi.x,
                    },
                ),
                try std.fmt.allocPrint( // 7
                    allocator,
                    "{s}IL>{s}{s}XX{s}XXXXXX{s}XX{s}{s}<JI{s}",
                    .{
                        ansi.y,  ansi.x,
                        ansi.dd, ansi.x,
                        ansi.dd, ansi.x,
                        ansi.y,  ansi.dd,
                    },
                ),
            },
        },
    };

    return logo;
}
