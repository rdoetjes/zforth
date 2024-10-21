const std = @import("std");

//this is a hack, i couldn't find a way to make Zig idomatic way work on macos
const c = @cImport({
    @cInclude("signal.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const Interpreter = @import("lexer.zig").Interpreter;
const builtin = @import("builtin");

const outw = std.io.getStdOut().writer();
var sig_int_interpreter: *Interpreter = undefined;

//this is a hack, i couldn't find a way to make Zig idomatic way work on macos
const SIGINT = 2; // Signal number for SIGINT
fn sigint_handler(_: i32) callconv(.C) void {
    std.debug.print("Breaking excution...\n", .{});
    sig_int_interpreter.set_break_flag();
}

fn read_forth_file(forth: *Interpreter, file_path: []const u8) !void {
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

fn read_forth_startup_files(forth: *Interpreter, allocator: std.mem.Allocator) !void {
    const exe_path = try std.fs.selfExePathAlloc(allocator);
    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";
    defer allocator.free(exe_path);

    const system_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "system.f" });
    defer allocator.free(system_path);
    const user_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "user.f" });
    defer allocator.free(user_path);

    try read_forth_file(forth, system_path);
    try read_forth_file(forth, user_path);
}

pub fn main() !void {
    const forth = try Interpreter.init(gpa_alloc);
    defer forth.deinit();
    sig_int_Interpreter = forth;

    //this is a hack, i couldn't find a way to make Zig idomatic way work on macos
    _ = c.signal(c.SIGINT, &sigint_handler);

    read_forth_startup_files(forth, gpa_alloc) catch |err| {
        try outw.print("Error reading forth startup files: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };

    try outw.print("Welcome to ZForth...\ntype bye to exit\n\n", .{});
    try forth.start_turn_key();

    while (true) {
        const line = try std.io.getStdIn().reader().readUntilDelimiterAlloc(gpa_alloc, '\n', 1024);

        forth.lex(line) catch |err| {
            try outw.print("Error: {s}\n", .{@errorName(err)});
        };
        gpa_alloc.free(line);
        try outw.print(" ok\n", .{});
    }
}
