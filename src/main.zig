const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig");
const outw = std.io.getStdOut().writer();

pub fn main() !void {
    while (true) {
        // line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);
        const line = "10 20 + .\n";

        const tokens = lexer.lex(gpa_alloc, line) catch |err| {
            try outw.print(">>{any}\n", .{err});
            continue;
        };

        lexer.print_tokens(tokens);
        tokens.deinit();
    }
}
