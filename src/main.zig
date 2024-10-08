const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();

var stack: *std.ArrayList(i32) = undefined;
// Define the function pointer type
const OpFunction = *const fn () error{OutOfMemory}!void;

// Create the HashMap
var operations: *std.StringHashMap(OpFunction) = undefined;

const Word = enum(i32) {
    int,
    plus,
    minus,
    dot_s,
    dot,
    star,

    pub fn toString(self: Word) []const u8 {
        return switch (self) {
            .plus => "+",
            .minus => "-",
            .dot_s => ".s",
            .dot => ".",
            .star => "*",
        };
    }
};

fn minus() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(b - a);
}

fn plus() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(a + b);
}

fn mul() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(a * b);
}

fn div() !void {
    const a = stack.*.pop();
    const b = stack.*.pop();
    try stack.*.append(@divFloor(b, a));
}
fn dot_s() !void {
    std.debug.print("{d} ", .{stack.*.items[stack.*.items.len - 1]});
}

fn dot() !void {
    const a = stack.*.pop();
    std.debug.print("{d}\n", .{a});
}

pub fn parse(line: []const u8) !void {
    var it = std.mem.split(u8, line, " ");
    while (it.next()) |word| {
        if (operations.*.get(word)) |op| {
            try op();
        } else {
            try stack.*.append(try std.fmt.parseInt(i32, word, 10));
        }
    }
}

pub fn main() !void {
    var local_stack = std.ArrayList(i32).init(gpa_alloc);
    defer local_stack.deinit();

    var operations_local = std.StringHashMap(OpFunction).init(gpa_alloc);
    defer operations.deinit();

    operations = &operations_local;
    try operations.put("+", plus);
    try operations.put("-", minus);
    try operations.put(".", dot);
    try operations.put(".s", dot_s);
    try operations.put("*", mul);
    try operations.put("/", div);

    stack = &local_stack;

    try parse("-5 6 - .");
}
