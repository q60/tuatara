pub const std = @import("std");
pub const mem = std.mem;
pub const fs = std.fs;
pub const os = std.os;
const stdout = std.io.getStdOut().writer();
pub const print = stdout.print;
pub const List = std.ArrayList;
