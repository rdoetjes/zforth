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

fn compile_world(start_index: *usize, line: []const u8) !usize {
    const dictionary_result = try get_word(&start_index, line);
    start_index = dictionary_result[0].*;
    const new_word = dictionary_result[1];
    std.debug.print("{s}", .{new_word});
    while (start_index <= line.len - 1 and line[start_index] != ';') {
        const word_ops_result = try get_word(&start_index, line);
        start_index = word_ops_result[0].*;
        const word_ops = word_ops_result[1];
        std.debug.print(">{s}< \n", .{word_ops});
    }
    start_index += 2;
    continue;
}

fn parse(line: []const u8) !void {
    var start_index: usize = 0;
    //this allows us to skip forward to closing parens by altering the start_index
    while (start_index < line.len) {
        const result = try get_word(&start_index, line);
        start_index = result[0].*;
        const word = result[1];

        const pruned_input = try gpa_alloc.alloc(u8, word.len);
        defer gpa_alloc.free(pruned_input);

        if (!std.mem.eql(u8, word, ".S")) _ = std.ascii.lowerString(pruned_input, word) else _ = std.mem.copyForwards(u8, pruned_input, word);

        if (word.len > 0 and word[0] == ':') {
            compile_world(&start_index, line);
            continue;
        }

        if (system_words.*.get(pruned_input)) |op| {
            const op_struct = try gpa_alloc.create(instructions.Op);
            op_struct.*.op = op;
            try op_stack.*.append(op_struct);
        } else {
            try arg_stack.*.append(try std.fmt.parseFloat(f32, word));
        }
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

    var l_system_words = std.StringHashMap(instructions.OpFunction).init(gpa_alloc);
    defer l_system_words.deinit();
    system_words = &l_system_words;

    try instructions.init_operations(&l_system_words, &l_arg_stack);

    try parse(": test 25 dup * . ; 25 3 * .S");
    try compile();
}
