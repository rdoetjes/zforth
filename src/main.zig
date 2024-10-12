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
        const line = " 1 0 20 do 1  + . cr loop";

        forth.lex(line);
        break;
    }
}
