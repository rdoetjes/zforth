const std = @import("std");
const Interpreter = @import("lexer.zig").Interpreter;
const outw = std.io.getStdOut().writer();

pub fn initImmediateWords(self: *Interpreter) !void {
    try self.dictionary.immediate_words.put(".", dot);
    try self.dictionary.immediate_words.put("cr", cr);
    try self.dictionary.immediate_words.put("dup", dup);
    try self.dictionary.immediate_words.put("+", add);
    try self.dictionary.immediate_words.put("*", mul);
    try self.dictionary.immediate_words.put("/", div);
    try self.dictionary.immediate_words.put(".s", dot_s);
    try self.dictionary.immediate_words.put(".S", dot_cap_s);
    try self.dictionary.immediate_words.put("over", over);
    try self.dictionary.immediate_words.put("swap", swap);
    try self.dictionary.immediate_words.put("rot", rot);
    try self.dictionary.immediate_words.put("drop", drop);
    try self.dictionary.immediate_words.put("=", equal);
    try self.dictionary.immediate_words.put(">", greater);
    try self.dictionary.immediate_words.put(">=", greater_or_equal);
    try self.dictionary.immediate_words.put("<=", less_or_equal);
    try self.dictionary.immediate_words.put("<", less);
    try self.dictionary.immediate_words.put("loop", do_nothing);
    try self.dictionary.immediate_words.put("then", do_nothing);
    try self.dictionary.immediate_words.put("else", do_nothing);
    try self.dictionary.immediate_words.put("begin", do_nothing);
    try self.dictionary.immediate_words.put("until", until);
    try self.dictionary.immediate_words.put("bye", exit);
    try self.dictionary.immediate_words.put("words", words);
    try self.dictionary.immediate_words.put("emit", emit);
    try self.dictionary.immediate_words.put("rnd", rnd);
}

fn do_nothing(_: *Interpreter) anyerror!void {}

fn exit(_: *Interpreter) !void {
    std.process.exit(0);
}

fn rnd(self: *Interpreter) !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const a: u32 = @intFromFloat(try self.stack.pop());
    const b: u32 = @intFromFloat(try self.stack.pop());
    const result = rand.intRangeAtMost(u32, b, a);
    try self.stack.append(@floatFromInt(result));
}

fn words(self: *Interpreter) !void {
    try outw.print("Buildin words:\n", .{});
    var iter = self.dictionary.immediate_words.keyIterator();
    while (iter.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }
    var iter1 = self.dictionary.compiled_words.keyIterator();
    while (iter1.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }

    try outw.print("\nExternal words:\n", .{});
    var iter2 = self.dictionary.user_words.keyIterator();
    while (iter2.next()) |key| {
        try outw.print("{s} ", .{key.*});
    }
}

fn over(self: *Interpreter) !void {
    const a = try self.stack.pop();
    const b = try self.stack.pop();
    try self.stack.append(b);
    try self.stack.append(a);
    try self.stack.append(b);
}

fn swap(self: *Interpreter) !void {
    const a = try self.stack.pop();
    const b = try self.stack.pop();
    try self.stack.append(a);
    try self.stack.append(b);
}

fn rot(self: *Interpreter) !void {
    const a = try self.stack.pop();
    const b = try self.stack.pop();
    const c = try self.stack.pop();

    try self.stack.append(b);
    try self.stack.append(a);
    try self.stack.append(c);
}

fn drop(self: *Interpreter) !void {
    _ = try self.stack.pop();
}

fn dup(self: *Interpreter) !void {
    if (self.stack.stack_value.items.len == 0) {
        return error.Stack_Underflow;
    }
    const a = try self.stack.pop();
    try self.stack.append(a);
    try self.stack.append(a);
}

fn add(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(a + b);
}

fn mul(self: *Interpreter) !void {
    const a = try self.stack.pop();
    const b = try self.stack.pop();
    try self.stack.append(a * b);
}

fn div(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(a / b);
}

fn dot_cap_s(self: *Interpreter) !void {
    try outw.print("S <{d}> ", .{self.stack.stack_value.items.len});
    for (self.stack.stack_value.items) |item| {
        try outw.print("{d} ", .{item});
    }
    try outw.print("\n", .{});
}

fn dot_s(self: *Interpreter) !void {
    if (self.stack.stack_value.items.len == 0) return error.Stack_Underflow;
    try outw.print("s {d} ", .{self.stack.stack_value.items[self.stack.stack_value.items.len - 1]});
}

fn dot(self: *Interpreter) !void {
    try outw.print("{d}", .{try self.stack.pop()});
}

fn cr(_: *Interpreter) !void {
    try outw.print("\n", .{});
}

fn equal(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(if (a == b) -1 else 0);
}

fn greater(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(if (a > b) -1 else 0);
}

fn less_or_equal(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(if (a <= b) -1 else 0);
}

fn greater_or_equal(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(if (a >= b) -1 else 0);
}

fn less(self: *Interpreter) !void {
    const b = try self.stack.pop();
    const a = try self.stack.pop();
    try self.stack.append(if (a < b) -1 else 0);
}

fn emit(self: *Interpreter) !void {
    const a = try self.stack.pop();
    const char: u8 = @intFromFloat(a);
    try outw.print("{c}", .{char});
}

fn until(self: *Interpreter) anyerror!void {
    const a = try self.stack.pop();
    if (a == -1) {
        self.break_flag = true;
    }
}
