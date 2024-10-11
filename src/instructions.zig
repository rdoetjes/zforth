const std = @import("std");
pub var arg_stack: *std.ArrayList(f32) = undefined;
const outw = std.io.getStdOut().writer();
const interpreter = @import("interpreter.zig");

pub const OpFunction = *const fn ([]const u8) anyerror!void;
pub const OpCompileFunction = *const fn ([]const u8, *usize) anyerror!void;

pub const Op = struct {
    words: []const u8, //contains the words of a user defined word (that will be parsed and run)
    op: OpFunction, //the function pointer of a system_word
    op_compile: OpCompileFunction, // the function pointer of a compile_word
    arg: []const u8, // the optional argumen for op function
};

fn pop() !f32 {
    if (arg_stack.*.items.len == 0) {
        return error.Stack_Underflow;
    }

    return arg_stack.*.pop();
}

pub fn do(code: []const u8) !void {
    const a: usize = @floatFromInt(try pop());
    const b: usize = @floatFromInt(try pop());
    for (a..b) |_| {
        interpreter.parse(code);
    }
}

pub fn minus(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(b - a);
}

pub fn plus(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(a + b);
}

pub fn mul(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(a * b);
}

pub fn div(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(b / a);
}

pub fn dot_s(_: []const u8) !void {
    if (arg_stack.*.items.len == 0) {
        return error.Stack_Underflow;
    }
    try outw.print(".s <1> {d}\n", .{arg_stack.*.items[arg_stack.*.items.len - 1]});
}

pub fn dot_cap_s(_: []const u8) !void {
    try outw.print(".S <{d}> ", .{arg_stack.*.items.len});
    for (arg_stack.*.items) |item| {
        try outw.print("{d} ", .{item});
    }
    try outw.print("\n", .{});
}

pub fn dot(_: []const u8) !void {
    const a = try pop();
    try outw.print("{d}", .{a});
}

pub fn dup(_: []const u8) !void {
    const a = try pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(a);
}

pub fn drop(_: []const u8) !void {
    _ = try pop();
}

pub fn swap(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(b);
}

pub fn over(_: []const u8) !void {
    const a = try pop();
    const b = try pop();
    try arg_stack.*.append(b);
    try arg_stack.*.append(a);
    try arg_stack.*.append(b);
}

pub fn sqrt(_: []const u8) !void {
    const a = try pop();
    try arg_stack.*.append(std.math.sqrt(a));
}

pub fn print(a: []const u8) !void {
    try outw.print("{s}", .{a});
}

pub fn cr(_: []const u8) !void {
    try outw.print("\n", .{});
}

pub fn push(a: []const u8) !void {
    const value = std.fmt.parseFloat(f32, a) catch {
        return error.Invalid_Number;
    };

    try arg_stack.*.append(value);
}

pub fn dot_dquote(line: []const u8, start_index: *usize) !void {
    const b_start_index = start_index.*;
    for (line[start_index.*..]) |c| {
        if (c != '"') start_index.* += 1 else break;
    }
    interpreter.handle_system_word(print, line[b_start_index..start_index.*]);
    start_index.* += 2;
}
