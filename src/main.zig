const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const instructions = @import("instructions.zig");
const outw = std.io.getStdOut().writer();

var system_words: *std.StringHashMap(instructions.OpFunction) = undefined;
var my_words: *std.StringHashMap(*instructions.Op) = undefined;

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

fn compile_word(start_index: *usize, line: []const u8) !void {
    const dictionary_result = try get_word(start_index, line);
    start_index.* = dictionary_result[0].*;
    const old_index = start_index.*;
    const new_word = dictionary_result[1];

    while (start_index.* <= line.len - 1 and line[start_index.*] != ';') {
        const word_ops_result = try get_word(&start_index.*, line);
        start_index.* = word_ops_result[0].*;
        const my_word = try gpa_alloc.create(instructions.Op);
        my_word.*.words = line[old_index..start_index.*];
        try my_words.*.put(new_word, my_word);
    }
    start_index.* += 2;
}

fn handle_system_word(op: *const fn ([]const u8) anyerror!void) void {
    const op_struct = gpa_alloc.create(instructions.Op) catch |err| {
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
    const op_struct = gpa_alloc.create(instructions.Op) catch |err| {
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
            try compile_word(&start_index, line);
            continue;
        }

        if (system_words.*.get(pruned_input)) |op| {
            handle_system_word(op);
        } else if (my_words.*.get(pruned_input)) |op| {
            try parse(op.*.words);
        } else {
            handle_stack_value(pruned_input);
        }
    }
}

fn compile() !void {
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
}

pub fn main() !void {
    var l_arg_stack = std.ArrayList(f32).init(gpa_alloc);
    defer l_arg_stack.deinit();
    arg_stack = &l_arg_stack;
    arg_stack.*.clearRetainingCapacity();

    var l_op_stack = std.ArrayList(*instructions.Op).init(gpa_alloc);
    defer l_op_stack.deinit();
    op_stack = &l_op_stack;
    op_stack.*.clearRetainingCapacity();

    var l_my_words = std.StringHashMap(*instructions.Op).init(gpa_alloc);
    defer l_my_words.deinit();
    my_words = &l_my_words;

    var l_system_words = std.StringHashMap(instructions.OpFunction).init(gpa_alloc);
    defer l_system_words.deinit();
    system_words = &l_system_words;

    try instructions.init_operations(&l_system_words, &l_arg_stack);

    parse(": two 2 ; two two * -2 .S + . . .") catch |err| {
        try outw.print("{}\n", .{err});
    };

    compile() catch |err| {
        try outw.print("{}\n", .{err});
    };
}
