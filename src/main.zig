const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const instructions = @import("instructions.zig");

var operations: *std.StringHashMap(instructions.OpFunction) = undefined;
var stack: *std.ArrayList(f32) = undefined;

fn parse(line: []const u8) !void {
    var it = std.mem.split(u8, line, " ");
    while (it.next()) |word| {
        const lower_word = try gpa_alloc.alloc(u8, word.len);
        _ = std.ascii.lowerString(lower_word, word);

        if (operations.*.get(lower_word)) |op| {
            try op();
        } else {
            try stack.*.append(try std.fmt.parseFloat(f32, word));
        }
        gpa_alloc.free(lower_word);
    }
}

pub fn main() !void {
    var local_stack = std.ArrayList(f32).init(gpa_alloc);
    defer local_stack.deinit();
    stack = &local_stack;

    var operations_local = std.StringHashMap(instructions.OpFunction).init(gpa_alloc);
    defer operations_local.deinit();
    operations = &operations_local;

    try instructions.init_operations(&operations_local, &local_stack);

    try parse("100 DUP / .S dRoP");
}
