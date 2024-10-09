const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const instructions = @import("instructions.zig");

var system_words: *std.StringHashMap(instructions.OpFunction) = undefined;

var arg_stack: *std.ArrayList(f32) = undefined;
var op_stack: *std.ArrayList(*instructions.Op) = undefined;

fn get_word(start_index: *usize, line: []const u8) !struct { *usize, []const u8 } {
    const start_pos = start_index.*;
    while (start_index.* <= line.len - 1 and line[start_index.*] != ' ') {
        start_index.* += 1;
    }

    start_index.* += 1;
    return .{ start_index, line[start_pos .. start_index.* - 1] };
}
fn parse(line: []const u8) !void {
    var start_index: usize = 0;
    //this allows us to skip forward to closing parens by altering the start_index
    while (start_index < line.len) {
        const result = try get_word(&start_index, line);
        start_index = result[0].*;
        const word = result[1];

        //this is the only situation where we use a capitalized word, the rest can be any case
        if (std.mem.eql(u8, word, ".S")) {
            if (system_words.*.get(word)) |op| {
                try op();
                continue;
            }
        }

        const lower_word = try gpa_alloc.alloc(u8, word.len);
        _ = std.ascii.lowerString(lower_word, word);

        if (system_words.*.get(lower_word)) |op| {
            const op_struct = try gpa_alloc.create(instructions.Op);
            op_struct.*.op = op;
            try op_stack.*.append(op_struct);
        } else {
            try arg_stack.*.append(try std.fmt.parseFloat(f32, word));
        }

        gpa_alloc.free(lower_word);
    }
}

fn compile() !void {
    for (op_stack.items) |op| {
        if (op.*.op != undefined) {
            try op.*.op();
        } else if (op.*.words.len > 0) {
            try parse(op.*.words);
            try compile();
        }
    }
}

pub fn main() !void {
    var l_arg_stack = std.ArrayList(f32).init(gpa_alloc);
    defer l_arg_stack.deinit();
    arg_stack = &l_arg_stack;

    var l_op_stack = std.ArrayList(*instructions.Op).init(gpa_alloc);
    defer l_op_stack.deinit();
    op_stack = &l_op_stack;

    var l_operations_local = std.StringHashMap(instructions.OpFunction).init(gpa_alloc);
    defer l_operations_local.deinit();
    system_words = &l_operations_local;

    try instructions.init_operations(&l_operations_local, &l_arg_stack);

    try parse("25 25 * .S");
    try compile();
}
