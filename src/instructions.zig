const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
pub const OpFunction = *const fn () anyerror!void;

var stack: *std.ArrayList(f32) = undefined;

pub fn init_operations(operations: *std.StringHashMap(OpFunction), local_stack: *std.ArrayList(f32)) !void {
    stack = local_stack;
    try operations.put("+", plus);
    try operations.put("-", minus);
    try operations.put(".", dot);
    try operations.put(".s", dot_s);
    try operations.put("*", mul);
    try operations.put("/", div);
    try operations.put("dup", dup);
}

pub fn minus() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(b - a);
}

pub fn plus() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(a + b);
}

pub fn mul() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(a * b);
}

pub fn div() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(b / a);
}

pub fn dot_s() !void {
    std.debug.print("{d} ", .{stack.*.items[stack.*.items.len - 1]});
}

pub fn dot() !void {
    const a = stack.*.pop();
    std.debug.print("{d}\n", .{a});
}

pub fn dup() !void {
    const a = stack.*.pop();
    try stack.*.append(a);
    try stack.*.append(a);
}
