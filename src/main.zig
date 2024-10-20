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
fn sigint_handler(_: i32) callconv(.C) void {
    std.debug.print("Breaking excution...\n", .{});
    sig_int_lexer.set_break_flag();
}

fn read_forth_file(forth: *lexer, file_path: []const u8) !void {
    var file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        try outw.print("Error open forth file {s}: {s}\n", .{ file_path, @errorName(err) });
        std.process.exit(1);
    };
    defer file.close();

    while (file.reader().readUntilDelimiterOrEofAlloc(gpa_alloc, '\n', std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |line| {
        defer gpa_alloc.free(line);
        forth.lex(line) catch |err| {
            try outw.print("Error reading forth from file: {s}\n", .{@errorName(err)});
            std.process.exit(1);
        };
    }
}

pub fn main() !void {
    const forth = try lexer.init(gpa_alloc);
    defer forth.deinit();
    sig_int_lexer = forth;

    //this is a hack, i couldn't find a way to make Zig idomatic way work on macos
    _ = c.signal(c.SIGINT, &sigint_handler);
    try read_forth_file(forth, "./system.f");
    try read_forth_file(forth, "./user.f");
    try outw.print("Welcome to ZForth...\ntype bye to exit\n\n", .{});
    while (true) {
        const line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);

        forth.lex(line) catch |err| {
            try outw.print("Error: {s}\n", .{@errorName(err)});
        };
        gpa_alloc.free(line);
        try outw.print(" ok\n", .{});
    }
}
