const std = @import("std");
const outw = std.io.getStdOut().writer();
const Interpreter = @import("lexer.zig").Interpreter;

pub fn initCompiledWords(interpreter: *Interpreter) !void {
    try interpreter.dictionary.compiled_words.put(".\"", print_string);
    try interpreter.dictionary.compiled_words.put(":", compile_word);
    try interpreter.dictionary.compiled_words.put("do", do_number);
    try interpreter.dictionary.compiled_words.put("if", if_then);
    try interpreter.dictionary.compiled_words.put("else", else_then);
    try interpreter.dictionary.compiled_words.put("repeat", repeat);
    try interpreter.dictionary.compiled_words.put("see", see);
    try interpreter.dictionary.compiled_words.put("begin", begin);
}

fn print_string(_: *Interpreter, line: []const u8, end_pos: *usize) !void {
    const new_end_pos = try Interpreter.find_end_marker(&line, end_pos.*, "\"");
    const start_pos = end_pos.*;
    const arg = line[start_pos + 1 .. new_end_pos];
    try outw.print("{s}", .{arg});
    end_pos.* = new_end_pos + 1;
}

fn begin(forth: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
    if (forth.sig_int) {
        end_pos.* = end_pos.* + 1;
        return;
    }
    end_pos.* = 0;
    end_pos.* = try Interpreter.find_end_marker(&line, end_pos.*, "repeat");
}

fn do_number(forth: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
    const new_end_pos = try Interpreter.find_end_marker(&line, end_pos.*, "loop");
    const start_pos = end_pos.*;
    const arg = line[start_pos + 1 .. new_end_pos];

    const a: usize = @intFromFloat(try forth.stack.pop());
    const b: usize = @intFromFloat(try forth.stack.pop());

    if (a > b) {
        return error.Loop_End_Greater_Than_Start;
    }

    for (a..b) |_| {
        try forth.lex(arg);
    }
    end_pos.* = new_end_pos + 5;
}

fn repeat(forth: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
    const new_end_pos_begin = try Interpreter.find_end_marker(&line, end_pos.*, "begin");
    const new_end_pos_until = try Interpreter.find_end_marker(&line, end_pos.*, "until");
    const new_end_pos = if (new_end_pos_begin > new_end_pos_until) new_end_pos_until + 5 else new_end_pos_begin;
    const start_pos = end_pos.*;
    const arg = line[start_pos + 1 .. new_end_pos];
    forth.break_flag = false;
    forth.sig_int = false;

    while (!forth.break_flag and !forth.sig_int) {
        try forth.lex(arg);
    }
    end_pos.* = new_end_pos;
}

fn if_then(forth: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
    var new_end_pos: usize = undefined;
    const then_pos = try Interpreter.find_end_marker(&line, end_pos.*, "then");
    const else_pos = Interpreter.find_end_marker(&line, end_pos.*, "else") catch |err| switch (err) {
        error.Marker_Not_Found => 0,
        else => return err,
    };

    if (else_pos == 0) new_end_pos = then_pos else new_end_pos = else_pos;

    const start_pos = end_pos.*;
    const arg = line[start_pos + 1 .. new_end_pos];
    const a = try forth.stack.pop();

    if (a == -1) {
        try forth.lex(arg);
        new_end_pos = then_pos;
        end_pos.* = new_end_pos + 5;
    } else if (else_pos != 0) {
        end_pos.* = else_pos;
    } else {
        end_pos.* = new_end_pos + 5;
    }
}

fn else_then(forth: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
    const new_end_pos = try Interpreter.find_end_marker(&line, end_pos.*, "then");
    const start_pos = end_pos.*;
    const arg = line[start_pos + 1 .. new_end_pos];

    try forth.lex(arg);
    end_pos.* = new_end_pos + 5;
}

fn compile_word(forth: *Interpreter, line: []const u8, end_pos: *usize) !void {
    end_pos.* += 1;

    if (end_pos.* >= line.len) return error.Marker_Not_Found;

    const word_end = Interpreter.find_end_current_token(&line, end_pos.*);

    const word = line[end_pos.*..word_end];
    const owned_key = try forth.allocator.dupe(u8, word);
    end_pos.* = word_end + 1;

    const definition_end = try Interpreter.find_end_marker(&line, end_pos.*, " ;");
    if (definition_end >= line.len) return error.Marker_Not_Found;
    const owned_stmnt = try forth.allocator.dupe(u8, line[end_pos.* .. definition_end + 1]);

    try forth.dictionary.user_words.put(owned_key, owned_stmnt);

    end_pos.* = definition_end + 2;
}

fn see(forth: *Interpreter, line: []const u8, end_pos: *usize) !void {
    const key = std.mem.trim(u8, line[end_pos.*..], " \t\n");
    end_pos.* = line.len;

    if (forth.dictionary.immediate_words.contains(key)) {
        try outw.print(" :\n : {s} {any} ;", .{ key, forth.dictionary.immediate_words.get(key) });
        return;
    }

    if (forth.dictionary.compiled_words.contains(key)) {
        try outw.print(" :\n : {s} {any} ;", .{ key, forth.dictionary.compiled_words.get(key) });
        return;
    }

    if (forth.dictionary.user_words.contains(key)) {
        const definition: []const u8 = forth.dictionary.user_words.get(key) orelse "";
        try outw.print(" : {s} {s} ;\n", .{ key, definition });
        return;
    }

    try outw.print("No word called {s}\n", .{key});
}
