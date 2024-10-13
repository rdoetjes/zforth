const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig").lexer;
const outw = std.io.getStdOut().writer();

pub fn main() !void {
    const forth = try lexer.init(gpa_alloc);
    defer (forth.deinit());
    try outw.print("Welcome to ZForth...\n", .{});
    while (true) {
        const line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);

        forth.lex(line) catch |err| {
            try outw.print("Error: {s}\n", .{@errorName(err)});
        };
        gpa_alloc.free(line);
        try outw.print(" ok\n", .{});
    }
}
