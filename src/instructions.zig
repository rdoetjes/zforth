const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
var operations: *std.StringHashMap(OpFunction) = undefined;
var arg_stack: *std.ArrayList(f32) = undefined;

pub const OpFunction = *const fn () anyerror!void;
pub const Op = struct {
    words: []const u8,
    op: OpFunction,
};

pub fn init_operations(l_system_words: *std.StringHashMap(OpFunction), l_arg_stack: *std.ArrayList(f32)) !void {
    arg_stack = l_arg_stack;
    operations = l_system_words;
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

pub fn minus() !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(b - a);
}

pub fn plus() !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a + b);
}

pub fn mul() !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a * b);
}

pub fn div() !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(b / a);
}

pub fn dot_s() !void {
    std.debug.print(".s <1> {d}\n", .{arg_stack.*.items[arg_stack.*.items.len - 1]});
}

pub fn dot_cap_s() !void {
    std.debug.print(".S <{d}> ", .{arg_stack.*.items.len});
    for (arg_stack.*.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
}

pub fn dot() !void {
    const a = arg_stack.*.pop();
    std.debug.print("{d}\n", .{a});
}

pub fn dup() !void {
    const a = arg_stack.*.pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(a);
}

pub fn drop() !void {
    _ = arg_stack.*.pop();
}

pub fn swap() !void {
    const a = arg_stack.*.pop();
    const b = arg_stack.*.pop();
    try arg_stack.*.append(a);
    try arg_stack.*.append(b);
}

pub fn sqrt() !void {
    const a = arg_stack.*.pop();
    try arg_stack.*.append(std.math.sqrt(a));
}

pub fn print(a: []const u8) !void {
    std.debug.print("{s}", .{a});
}
