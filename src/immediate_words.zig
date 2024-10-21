const std = @import("std");
const Interpreter = @import("lexer.zig").Interpreter;
const outw = std.io.getStdOut().writer();

pub fn initImmediateWords(forth: *Interpreter) !void {
    try forth.dictionary.immediate_words.put(".", dot);
    try forth.dictionary.immediate_words.put("cr", cr);
    try forth.dictionary.immediate_words.put("dup", dup);
    try forth.dictionary.immediate_words.put("+", add);
    try forth.dictionary.immediate_words.put("*", mul);
    try forth.dictionary.immediate_words.put("/", div);
    try forth.dictionary.immediate_words.put(".s", dot_s);
    try forth.dictionary.immediate_words.put(".S", dot_cap_s);
    try forth.dictionary.immediate_words.put("over", over);
    try forth.dictionary.immediate_words.put("swap", swap);
    try forth.dictionary.immediate_words.put("rot", rot);
    try forth.dictionary.immediate_words.put("drop", drop);
    try forth.dictionary.immediate_words.put("=", equal);
    try forth.dictionary.immediate_words.put(">", greater);
    try forth.dictionary.immediate_words.put(">=", greater_or_equal);
    try forth.dictionary.immediate_words.put("<=", less_or_equal);
    try forth.dictionary.immediate_words.put("<", less);
    try forth.dictionary.immediate_words.put("loop", do_nothing);
    try forth.dictionary.immediate_words.put("then", do_nothing);
    try forth.dictionary.immediate_words.put("else", do_nothing);
    try forth.dictionary.immediate_words.put("begin", do_nothing);
    try forth.dictionary.immediate_words.put("until", until);
    try forth.dictionary.immediate_words.put("bye", exit);
    try forth.dictionary.immediate_words.put("words", words);
    try forth.dictionary.immediate_words.put("emit", emit);
    try forth.dictionary.immediate_words.put("rnd", rnd);
}

fn do_nothing(_: *Interpreter) anyerror!void {}

fn exit(_: *Interpreter) !void {
    std.process.exit(0);
}

fn rnd(forth: *Interpreter) !void {
    const rand = forth.prng.random();

    const a: u32 = @intFromFloat(try forth.stack.pop());
    const b: u32 = @intFromFloat(try forth.stack.pop());
    const result = rand.intRangeAtMost(u32, b, a);
    try forth.stack.append(@floatFromInt(result));
}

fn words(forth: *Interpreter) !void {
    try outw.print("Buildin words:\n", .{});
    var iter = forth.dictionary.immediate_words.keyIterator();
    while (iter.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }
    var iter1 = forth.dictionary.compiled_words.keyIterator();
    while (iter1.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }

    try outw.print("\nExternal words:\n", .{});
    var iter2 = forth.dictionary.user_words.keyIterator();
    while (iter2.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }
}

fn over(forth: *Interpreter) !void {
    const a = try forth.stack.pop();
    const b = try forth.stack.pop();
    try forth.stack.append(b);
    try forth.stack.append(a);
    try forth.stack.append(b);
}

fn swap(forth: *Interpreter) !void {
    const a = try forth.stack.pop();
    const b = try forth.stack.pop();
    try forth.stack.append(a);
    try forth.stack.append(b);
}

fn rot(forth: *Interpreter) !void {
    const a = try forth.stack.pop();
    const b = try forth.stack.pop();
    const c = try forth.stack.pop();

    try forth.stack.append(b);
    try forth.stack.append(a);
    try forth.stack.append(c);
}

fn drop(forth: *Interpreter) !void {
    _ = try forth.stack.pop();
}

fn dup(forth: *Interpreter) !void {
    if (forth.stack.stack_value.items.len == 0) {
        return error.Stack_Underflow;
    }
    const a = try forth.stack.pop();
    try forth.stack.append(a);
    try forth.stack.append(a);
}

fn add(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(a + b);
}

fn mul(forth: *Interpreter) !void {
    const a = try forth.stack.pop();
    const b = try forth.stack.pop();
    try forth.stack.append(a * b);
}

fn div(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(a / b);
}

fn dot_cap_s(forth: *Interpreter) !void {
    try outw.print("S <{d}> ", .{forth.stack.stack_value.items.len});
    for (forth.stack.stack_value.items) |item| {
        try outw.print("{d} ", .{item});
    }
    try outw.print("\n", .{});
}

fn dot_s(forth: *Interpreter) !void {
    if (forth.stack.stack_value.items.len == 0) return error.Stack_Underflow;
    try outw.print("s {d} ", .{forth.stack.stack_value.items[forth.stack.stack_value.items.len - 1]});
}

fn dot(forth: *Interpreter) !void {
    try outw.print("{d}", .{try forth.stack.pop()});
}

fn cr(_: *Interpreter) !void {
    try outw.print("\n", .{});
}

fn equal(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(if (a == b) -1 else 0);
}

fn greater(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(if (a > b) -1 else 0);
}

fn less_or_equal(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(if (a <= b) -1 else 0);
}

fn greater_or_equal(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(if (a >= b) -1 else 0);
}

fn less(forth: *Interpreter) !void {
    const b = try forth.stack.pop();
    const a = try forth.stack.pop();
    try forth.stack.append(if (a < b) -1 else 0);
}

fn emit(forth: *Interpreter) !void {
    const a = try forth.stack.pop();
    const char: u8 = @intFromFloat(a);
    try outw.print("{c}", .{char});
}

fn until(forth: *Interpreter) anyerror!void {
    const a = try forth.stack.pop();
    if (a == -1) {
        forth.break_flag = true;
    }
}
