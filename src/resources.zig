const Colors = struct {
    w: []const u8, ww: []const u8,
    r: []const u8, rr: []const u8,
    g: []const u8, gg: []const u8,
    y: []const u8, yy: []const u8,
    b: []const u8, bb: []const u8,
    m: []const u8, mm: []const u8,
    c: []const u8, cc: []const u8,
    d: []const u8, dd: []const u8,
    x: []const u8, z:  []const u8,
};

pub const ansi = Colors {
    .w = "\x1B[30m", .ww = "\x1B[90m",
    .r = "\x1B[31m", .rr = "\x1B[91m",
    .g = "\x1B[32m", .gg = "\x1B[92m",
    .y = "\x1B[33m", .yy = "\x1B[93m",
    .b = "\x1B[34m", .bb = "\x1B[94m",
    .m = "\x1B[35m", .mm = "\x1B[95m",
    .c = "\x1B[36m", .cc = "\x1B[96m",
    .d = "\x1B[37m", .dd = "\x1B[97m",
    .x = "\x1B[0m",  .z  = "\x1B[1m",
};
