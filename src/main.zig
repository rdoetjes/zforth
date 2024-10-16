const std = @import("std");

//this is a hack, i couldn't find a way to make Zig idomatic way work on macos
const c = @cImport({
    @cInclude("signal.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const lexer = @import("lexer.zig").lexer;
const builtin = @import("builtin");

const outw = std.io.getStdOut().writer();
var sig_int_lexer: *lexer = undefined;

//this is a hack, i couldn't find a way to make Zig idomatic way work on macos
const SIGINT = 2; // Signal number for SIGINT
fn sigint_handler(signum: i32) callconv(.C) void {
    std.debug.print("Received SIGINT {d}\n", .{signum});
    sig_int_lexer.set_break_flag();
}

pub fn main() !void {
    const forth = try lexer.init(gpa_alloc);
    defer forth.deinit();
    sig_int_lexer = forth;

    //this is a hack, i couldn't find a way to make Zig idomatic way work on macos
    _ = c.signal(c.SIGINT, &sigint_handler);

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
