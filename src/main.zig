const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const instructions = @import("instructions.zig");

var operations: *std.StringHashMap(instructions.OpFunction) = undefined;
var stack: *std.ArrayList(f32) = undefined;
var pstack: *std.ArrayList(f32) = undefined;

fn get_word(start_index: *usize, line: []const u8) !struct { *usize, []const u8 } {
    const start_pos = start_index.*;
    while (line[start_index.*] != ' ' and start_index.* < line.len - 1) {
        start_index.* += 1;
    }
    return .{ start_index, line[start_pos..start_index.*] };
}

fn parse(line: []const u8) !void {
    var start_index: usize = 0;
    //this allows us to skip forward to closing parens by altering the start_index
    while (start_index < line.len) {
        const result = try get_word(&start_index, line);
        start_index = result[0].* + 1;
        const word = result[1];

        //this is the only situation where we use a capitalized word, the rest can be any case
        if (std.mem.eql(u8, word, ".S")) {
            if (operations.*.get(word)) |op| {
                try op();
            }
        }

        if (word[0] == ':') {
            std.debug.print("{s}", .{line[start_index .. line.len - 1]});
            if (!std.mem.containsAtLeast(u8, line[start_index..line.len], 1, " ;")) {
                return error.Colon_Without_Semicolon;
            }
        }

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

    try parse("25 25 * .s :test dup * ;");
}
