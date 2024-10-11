const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig");

pub fn main() !void {
    while (true) {
        // line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);
        const line = "PUSH .\"\n";

        const tokens = lexer.lex(gpa_alloc, line) catch |err| {
            std.debug.panic("{any}", .{err});
        };

        lexer.print_tokens(tokens);
        tokens.deinit();
    }
}
