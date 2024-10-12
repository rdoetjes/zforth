const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig").lexer;
const outw = std.io.getStdOut().writer();

pub fn main() !void {
    const forth = try lexer.init(gpa_alloc);
    defer (forth.deinit());

    while (true) {
        //const line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);
        const line = "10 20 .\" the answer is: \" * . cr";

        forth.lex(line) catch |err| {
            std.debug.print("Error: {any}\n", .{err});
        };
        break;
    }
}
