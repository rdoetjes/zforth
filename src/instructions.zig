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
    try operations.put(".S", dot_cap_s);
    try operations.put("*", mul);
    try operations.put("/", div);
    try operations.put("dup", dup);
    try operations.put("drop", drop);
    try operations.put("swap", swap);
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
    std.debug.print(".s <1> {d}\n", .{stack.*.items[stack.*.items.len - 1]});
}

pub fn dot_cap_s() !void {
    std.debug.print(".S <{d}> ", .{stack.*.items.len});
    for (stack.*.items) |item| {
        std.debug.print("{d} ", .{item});
    }
    std.debug.print("\n", .{});
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

pub fn drop() !void {
    _ = stack.*.pop();
}

pub fn swap() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(a);
    try stack.*.append(b);
}
