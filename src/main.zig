const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig").lexer;
const builtin = @import("builtin");

const outw = std.io.getStdOut().writer();
const os = std.os;
var sig_int_lexer: *lexer = undefined;

// Function to manage CTRL + C to be implemented on drawin
fn sigintHandler(sig: c_int) callconv(.C) void {
    _ = sig;
    std.debug.print("Breaking execution\n", .{});
    sig_int_lexer.set_break_flag();
}

pub fn main() !void {
    const forth = try lexer.init(gpa_alloc);
    defer forth.deinit();
    sig_int_lexer = forth;

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
