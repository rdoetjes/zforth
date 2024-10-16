const std = @import("std");
const outw = std.io.getStdOut().writer();

const ImmediateFunction = *const fn (*lexer) anyerror!void;
const CompiledFunction = *const fn (*lexer, []const u8, *usize) anyerror!void;

pub const lexer = struct {
    stack: std.ArrayList(f32),
    allocator: std.mem.Allocator,
    user_words: std.StringHashMap([]const u8),
    immediate_words: std.StringHashMap(ImmediateFunction),
    compiled_words: std.StringHashMap(CompiledFunction),
    break_flag: bool,

    pub fn init(allocator: std.mem.Allocator) !*lexer {
        const self = try allocator.create(lexer);
        self.* = .{
            .stack = std.ArrayList(f32).init(allocator),
            .allocator = allocator,
            .user_words = std.StringHashMap([]const u8).init(allocator),
            .immediate_words = std.StringHashMap(ImmediateFunction).init(allocator),
            .compiled_words = std.StringHashMap(CompiledFunction).init(allocator),
            .break_flag = false,
        };

        try self.immediate_words.put(".", dot);
        try self.immediate_words.put("cr", cr);
        try self.immediate_words.put("dup", dup);
        try self.immediate_words.put("+", add);
        try self.immediate_words.put("*", mul);
        try self.immediate_words.put("/", div);
        try self.immediate_words.put(".s", dot_s);
        try self.immediate_words.put(".S", dot_cap_s);
        try self.immediate_words.put("over", over);
        try self.immediate_words.put("swap", swap);
        try self.immediate_words.put("rot", rot);
        try self.immediate_words.put("drop", drop);
        try self.immediate_words.put("=", equal);
        try self.immediate_words.put(">", greater);
        try self.immediate_words.put(">=", greater_or_equal);
        try self.immediate_words.put("<=", less_or_equal);
        try self.immediate_words.put("<", less);
        try self.immediate_words.put("loop", do_nothing);
        try self.immediate_words.put("then", do_nothing);
        try self.immediate_words.put("else", do_nothing);
        try self.immediate_words.put("begin", do_nothing);
        try self.immediate_words.put("until", until);

        try self.compiled_words.put(".\"", print_string);
        try self.compiled_words.put(":", compile_word);
        try self.compiled_words.put("do", do_number);
        try self.compiled_words.put("if", if_then);
        try self.compiled_words.put("else", else_then);
        try self.compiled_words.put("repeat", repeat);

        return self;
    }

    pub fn deinit(self: *lexer) void {
        self.stack.deinit();
        std.heap.page_allocator.destroy(self);
    }

    fn peek(line: []const u8, pos: usize) u8 {
        if (pos + 1 < line.len) return line[pos + 1] else return 0;
    }

    fn skip_white_spaces(line: *const []const u8, pos: usize) usize {
        var t_pos = pos;
        while (t_pos < line.*.len and (line.*[t_pos] == ' ' or line.*[t_pos] == '\n')) {
            t_pos += 1;
        }
        return t_pos;
    }

    fn find_end_current_token(line: *const []const u8, pos: usize) usize {
        var end_pos = pos;
        while (end_pos < line.*.len and line.*[end_pos] != ' ' and line.*[end_pos] != '\n') {
            end_pos += 1;
        }
        return end_pos;
    }

    fn find_end_marker(line: *const []const u8, pos: usize, marker: []const u8) !usize {
        var current_pos = pos + 1;
        var in_quotes = false;

        if (std.mem.eql(u8, marker, "\"")) {
            if (std.mem.indexOf(u8, line.*[pos + 1 ..], marker)) |t_pos| {
                return pos + t_pos + 1;
            }
        }

        while (current_pos < line.len) {
            if (line.*[current_pos] == '"') {
                in_quotes = !in_quotes;
            } else if (!in_quotes) {
                if (std.mem.startsWith(u8, line.*[current_pos..], marker)) {
                    return current_pos;
                }
            }
            current_pos += 1;
        }
        return line.*.len;
    }

    fn check_if_number(line: *const []const u8) bool {
        var t_pos: usize = 0;
        while (t_pos < line.*.len and line.*[t_pos] != ' ' and line.*[t_pos] != '\n') {
            if (line.*[t_pos] == '.') {
                t_pos += 1;
            } else if (line.*[t_pos] < '0' or line.*[t_pos] > '9') {
                return false;
            } else {
                t_pos += 1;
            }
        }
        return true;
    }

    fn do_nothing(_: *lexer) anyerror!void {}

    fn over(self: *lexer) !void {
        const a = try self.pop();
        const b = try self.pop();
        try self.stack.append(b);
        try self.stack.append(a);
        try self.stack.append(b);
    }

    fn swap(self: *lexer) !void {
        const a = try self.pop();
        const b = try self.pop();
        try self.stack.append(a);
        try self.stack.append(b);
    }

    fn rot(self: *lexer) !void {
        const a = try self.pop();
        const b = try self.pop();
        const c = try self.pop();

        try self.stack.append(b);
        try self.stack.append(a);
        try self.stack.append(c);
    }

    fn drop(self: *lexer) !void {
        _ = try self.pop();
    }

    fn pop(self: *lexer) !f32 {
        if (self.stack.items.len == 0) {
            return error.Stack_Underflow;
        }
        const a = self.stack.pop();
        return a;
    }

    fn dup(self: *lexer) !void {
        if (self.stack.items.len == 0) {
            return error.Stack_Underflow;
        }
        const a = self.stack.pop();
        try self.stack.append(a);
        try self.stack.append(a);
    }

    fn add(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(a + b);
    }

    fn mul(self: *lexer) !void {
        const a = try self.pop();
        const b = try self.pop();
        try self.stack.append(a * b);
    }

    fn div(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(a / b);
    }

    fn dot_cap_s(self: *lexer) !void {
        try outw.print("S <{d}> ", .{self.stack.items.len});
        for (self.stack.items) |item| {
            try outw.print("{d} ", .{item});
        }
        try outw.print("\n", .{});
    }

    fn dot_s(self: *lexer) !void {
        try outw.print("s {d} ", .{self.stack.items[self.stack.items.len - 1]});
    }

    fn dot(self: *lexer) !void {
        try outw.print("{d}", .{try self.pop()});
    }

    fn cr(_: *lexer) !void {
        try outw.print("\n", .{});
    }

    fn equal(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(if (a == b) -1 else 0);
    }

    fn greater(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(if (a > b) -1 else 0);
    }

    fn less_or_equal(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(if (a <= b) -1 else 0);
    }

    fn greater_or_equal(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(if (a >= b) -1 else 0);
    }

    fn less(self: *lexer) !void {
        const b = try self.pop();
        const a = try self.pop();
        try self.stack.append(if (a < b) -1 else 0);
    }

    fn print_string(_: *lexer, line: []const u8, end_pos: *usize) !void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "\"");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        try outw.print("{s}", .{arg});
        end_pos.* = new_end_pos + 1;
    }

    fn do_number(self: *lexer, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "loop");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];

        const b: usize = @intFromFloat(try self.pop());
        const a: usize = @intFromFloat(try self.pop());

        if (a > b) {
            return error.Loop_End_Greater_Than_Start;
        }

        for (a..b) |_| {
            try self.lex(arg);
        }
        end_pos.* = new_end_pos + 5;
    }

    fn repeat(self: *lexer, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "begin");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        self.break_flag = false;

        while (!self.break_flag) {
            try self.lex(arg);
        }
        end_pos.* = new_end_pos + 5;
    }

    fn until(self: *lexer) anyerror!void {
        const a = try self.pop();
        if (a == -1) {
            self.break_flag = true;
        }
    }

    fn if_then(self: *lexer, line: []const u8, end_pos: *usize) anyerror!void {
        var new_end_pos: usize = undefined;
        const then_pos = try find_end_marker(&line, end_pos.*, "then");
        const else_pos = find_end_marker(&line, end_pos.*, "else") catch |err| switch (err) {
            error.Marker_Not_Found => 0,
            else => return err,
        };

        if (else_pos == 0) new_end_pos = then_pos else new_end_pos = else_pos;

        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        const a = try self.pop();

        if (a == -1) {
            try self.lex(arg);
            new_end_pos = then_pos;
            end_pos.* = new_end_pos + 5;
        } else if (else_pos != 0) {
            end_pos.* = else_pos;
        } else {
            end_pos.* = new_end_pos + 5;
        }
    }

    fn else_then(self: *lexer, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "then");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];

        try self.lex(arg);
        end_pos.* = new_end_pos + 5;
    }

    fn compile_word(self: *lexer, line: []const u8, end_pos: *usize) !void {
        end_pos.* += 1;

        if (end_pos.* >= line.len) return error.Marker_Not_Found;

        const word_end = find_end_current_token(&line, end_pos.*);

        const word = line[end_pos.*..word_end];
        const owned_key = try self.allocator.dupe(u8, word);
        end_pos.* = word_end + 1;

        const definition_end = try find_end_marker(&line, end_pos.*, " ;");
        if (definition_end >= line.len) return error.Marker_Not_Found;
        const owned_stmnt = try self.allocator.dupe(u8, line[end_pos.* .. definition_end + 1]);

        try self.user_words.put(owned_key, owned_stmnt);

        end_pos.* = definition_end + 2;
    }

    pub fn lex(self: *lexer, line: []const u8) anyerror!void {
        var pos: usize = 0;

        while (pos < line.len) {
            pos = skip_white_spaces(&line, pos);
            if (pos >= line.len) break;
            var end_pos = find_end_current_token(&line, pos);

            // Match token
            const token_text = line[pos..end_pos];
            if (self.user_words.get(token_text)) |stmnt| {
                try self.lex(stmnt);
            } else if (self.compiled_words.get(token_text)) |word| {
                try word(self, line, &end_pos);
            } else if (self.immediate_words.get(token_text)) |word| {
                try word(self);
            } else {
                // Handle other token types or unknown tokens here
                if (check_if_number(&line[pos..end_pos])) {
                    const number = std.fmt.parseFloat(f32, token_text) catch {
                        return error.Invalid_Number;
                    };
                    try self.stack.append(number);
                } else {
                    std.debug.print("{s} causes an ", .{token_text});
                    return error.Invalid_Word;
                }
            }

            pos = end_pos;
        }
    }
};
