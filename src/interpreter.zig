const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();

var system_words: *std.StringHashMap(OpFunction) = undefined;
var my_words: *std.StringHashMap(*Op) = undefined;

var arg_stack: *std.ArrayList(f32) = undefined;
var op_stack: *std.ArrayList(*Op) = undefined;

const instructions = @import("instructions.zig");

pub const OpFunction = *const fn ([]const u8) anyerror!void;

pub const Op = struct {
    words: []const u8,
    op: OpFunction,
    arg: []const u8,
};

fn init_system_words() !void {
    try system_words.put("push", instructions.push);
    try system_words.put("+", instructions.plus);
    try system_words.put(".", instructions.dot);
    try system_words.put(".s", instructions.dot_s);
    try system_words.put(".S", instructions.dot_cap_s);
    try system_words.put("*", instructions.mul);
    try system_words.put("/", instructions.div);
    try system_words.put("dup", instructions.dup);
    try system_words.put("drop", instructions.drop);
    try system_words.put("swap", instructions.swap);
    try system_words.put("sqr", instructions.sqrt);
}

pub fn init_operations(l_system_words: *std.StringHashMap(OpFunction), l_arg_stack: *std.ArrayList(f32), l_op_stack: *std.ArrayList(*Op), l_my_words: *std.StringHashMap(*Op)) !void {
    arg_stack = l_arg_stack;
    system_words = l_system_words;
    op_stack = l_op_stack;
    my_words = l_my_words;
    instructions.arg_stack = l_arg_stack;

    try init_system_words();
}

fn get_word(start_index: *usize, line: []const u8) !struct { *usize, []const u8 } {
    const start_pos = start_index.*;
    while (start_index.* <= line.len - 1 and line[start_index.*] != ' ') {
        start_index.* += 1;
    }

    start_index.* += 1;
    return .{ start_index, line[start_pos .. start_index.* - 1] };
}

fn compile_word(start_index: *usize, line: []const u8) !void {
    const dictionary_result = try get_word(start_index, line);
    start_index.* = dictionary_result[0].*;
    const old_index = start_index.*;
    const new_word = dictionary_result[1];

    while (start_index.* <= line.len - 1 and line[start_index.*] != ';') {
        const word_ops_result = try get_word(&start_index.*, line);
        start_index.* = word_ops_result[0].*;

        const my_word = try gpa_alloc.create(Op);
        my_word.*.arg = "";

        const t = line[old_index..start_index.*];
        my_word.*.words = try gpa_alloc.dupe(u8, t);

        const new_word_ptr = try gpa_alloc.dupe(u8, new_word);
        try my_words.*.put(new_word_ptr, my_word);
    }
    start_index.* += 2;
}

fn handle_system_word(op: *const fn ([]const u8) anyerror!void) void {
    const op_struct = gpa_alloc.create(Op) catch |err| {
        std.debug.panic("failed to allocate memory, when creating operation entry: {}\n", .{err});
    };

    op_struct.*.op = op;
    const none_str = "";
    op_struct.*.arg = gpa_alloc.dupe(u8, none_str) catch |err| {
        std.debug.panic("failed to allocate memory: {}\n", .{err});
    };

    op_stack.*.append(op_struct) catch |err| {
        std.debug.panic("failed to allocate memory to push instruction onto op_stack: {}\n", .{err});
    };
}

fn handle_stack_value(value: []const u8) void {
    const op_struct = gpa_alloc.create(Op) catch |err| {
        std.debug.panic("failed to allocate memory, when creating stack entry: {}\n", .{err});
    };

    op_struct.*.op = instructions.push;
    op_struct.*.arg = gpa_alloc.dupe(u8, value) catch |err| {
        std.debug.panic("failed to allocate memory when copying value {s} : {}\n", .{ value, err });
    };

    op_stack.*.append(op_struct) catch |err| {
        std.debug.panic("failed to allocate memory to push instruction onto stack: {}\n", .{err});
    };
}

pub fn parse(line: []const u8) !void {
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
            try compile_word(&start_index, line);
            continue;
        }
        std.debug.print("word: {s}\n", .{word});
        if (system_words.*.get(pruned_input)) |op| {
            std.debug.print("word op: {s}\n", .{word});
            handle_system_word(op);
        } else if (my_words.*.get(pruned_input)) |op| {
            try parse(op.*.words);
        } else {
            std.debug.print("word sta op: {s}\n", .{pruned_input});
            handle_stack_value(pruned_input);
        }
    }
}

pub fn compile() !void {
    for (op_stack.items) |op| {
        if (op.*.op != undefined) {
            try op.*.op(op.*.arg);
            gpa_alloc.free(op.*.arg);
        } else if (op.*.words.len > 0) {
            try parse(op.*.words);
            try compile();
        }
        gpa_alloc.destroy(op);
    }
    op_stack.*.clearRetainingCapacity();
}
