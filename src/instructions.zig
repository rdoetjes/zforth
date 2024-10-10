const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
var operations: *std.StringHashMap(OpFunction) = undefined;
var arg_stack: *std.ArrayList(f32) = undefined;
const outw = std.io.getStdOut().writer();

pub const OpFunction = *const fn ([]const u8) anyerror!void;
pub const Op = struct {
    words: []const u8,
    op: OpFunction,
    arg: []const u8,
};

pub fn init_operations(l_system_words: *std.StringHashMap(OpFunction), l_arg_stack: *std.ArrayList(f32)) !void {
    arg_stack = l_arg_stack;
    operations = l_system_words;
    try operations.put("push", push);
    try operations.put("+", plus);
    try operations.put("-", minus);
    try operations.put(".", dot);
    try operations.put(".s", dot_s);
    try operations.put(".S", dot_cap_s);
    try operations.put("*", mul);
    try operations.put("/", div);
    try operations.put("dup", dup);
    try operations.put("drop", drop);
    try operations.put("swap", swap);
    try operations.put("sqr", sqrt);
}

pub fn minus(_: []const u8) !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(b - a);
}

pub fn plus(_: []const u8) !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a + b);
}

pub fn mul(_: []const u8) !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a * b);
}

pub fn div(_: []const u8) !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(b / a);
}

pub fn dot_s(_: []const u8) !void {
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
    const a = arg_stack.*.pop();
    try outw.print("{d}\n", .{a});
}

pub fn dup(_: []const u8) !void {
    const a = arg_stack.*.pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(a);
}

pub fn drop(_: []const u8) !void {
    _ = arg_stack.*.pop();
}

pub fn swap(_: []const u8) !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(b);
}

pub fn sqrt(_: []const u8) !void {
    const a = arg_stack.*.pop();
    try arg_stack.*.append(std.math.sqrt(a));
}

pub fn print(a: []const u8) !void {
    try outw.print("{s}", .{a});
}

pub fn push(a: []const u8) !void {
    const value = std.fmt.parseFloat(f32, a) catch {
        return error.Invalid_Number;
    };

    try arg_stack.*.append(value);
}
