const std = @import("std");
const outw = std.io.getStdOut().writer();
const immediate_words = @import("immediate_words.zig");

const ImmediateFunction = *const fn (*Interpreter) anyerror!void;
const CompiledFunction = *const fn (*Interpreter, []const u8, *usize) anyerror!void;

pub const Stack = struct {
    stack_value: std.ArrayList(f32),

    pub fn init(allocator: std.mem.Allocator) Stack {
        return .{ .stack_value = std.ArrayList(f32).init(allocator) };
    }

    pub fn deinit(self: *Stack) void {
        self.stack_value.deinit();
    }

    pub fn len(self: *Stack) usize {
        return self.stack_value.items.len;
    }

    // Add methods like push, pop, peek, etc.
    pub fn pop(self: *Stack) !f32 {
        if (self.stack_value.items.len == 0) {
            return error.Stack_Underflow;
        }
        const a = self.stack_value.pop();
        return a;
    }

    pub fn append(self: *Stack, float: f32) !void {
        try self.stack_value.append(float);
        return;
    }
};

pub const Dictionary = struct {
    user_words: std.StringHashMap([]const u8),
    immediate_words: std.StringHashMap(ImmediateFunction),
    compiled_words: std.StringHashMap(CompiledFunction),

    pub fn init(allocator: std.mem.Allocator) Dictionary {
        return .{
            .user_words = std.StringHashMap([]const u8).init(allocator),
            .immediate_words = std.StringHashMap(ImmediateFunction).init(allocator),
            .compiled_words = std.StringHashMap(CompiledFunction).init(allocator),
        };
    }

    pub fn deinit(self: *Dictionary) void {
        self.user_words.deinit();
        self.immediate_words.deinit();
        self.compiled_words.deinit();
    }

    // Add methods for adding and looking up words
};

pub const Interpreter = struct {
    break_flag: bool,
    allocator: std.mem.Allocator,
    stack: Stack,
    dictionary: Dictionary,

    fn initCompiledWords(self: *Interpreter) !void {
        try self.dictionary.compiled_words.put(".\"", print_string);
        try self.dictionary.compiled_words.put(":", compile_word);
        try self.dictionary.compiled_words.put("do", do_number);
        try self.dictionary.compiled_words.put("if", if_then);
        try self.dictionary.compiled_words.put("else", else_then);
        try self.dictionary.compiled_words.put("repeat", repeat);
        try self.dictionary.compiled_words.put("see", see);
    }

    pub fn init(allocator: std.mem.Allocator) !*Interpreter {
        const self = try allocator.create(Interpreter);
        self.* = .{
            .stack = Stack.init(allocator),
            .allocator = allocator,
            .dictionary = Dictionary.init(allocator),
            .break_flag = false,
        };

        try immediate_words.initImmediateWords(self);
        try self.initCompiledWords();

        return self;
    }

    pub fn deinit(self: *Interpreter) void {
        self.stack.deinit();
        self.dictionary.deinit();
        self.allocator.destroy(self);
    }

    fn peek(line: []const u8, pos: usize) u8 {
        if (pos + 1 < line.len) return line[pos + 1] else return 0;
    }

    pub fn set_break_flag(self: *Interpreter) void {
        self.break_flag = true;
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

    fn print_string(_: *Interpreter, line: []const u8, end_pos: *usize) !void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "\"");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        try outw.print("{s}", .{arg});
        end_pos.* = new_end_pos + 1;
    }

    fn do_number(self: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "loop");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];

        const b: usize = @intFromFloat(try self.stack.pop());
        const a: usize = @intFromFloat(try self.stack.pop());

        if (a > b) {
            return error.Loop_End_Greater_Than_Start;
        }

        for (a..b) |_| {
            try self.lex(arg);
        }
        end_pos.* = new_end_pos + 5;
    }

    fn repeat(self: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "begin");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        self.break_flag = false;

        while (!self.break_flag) {
            try self.lex(arg);
        }
        end_pos.* = new_end_pos + 5;
    }

    fn if_then(self: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
        var new_end_pos: usize = undefined;
        const then_pos = try find_end_marker(&line, end_pos.*, "then");
        const else_pos = find_end_marker(&line, end_pos.*, "else") catch |err| switch (err) {
            error.Marker_Not_Found => 0,
            else => return err,
        };

        if (else_pos == 0) new_end_pos = then_pos else new_end_pos = else_pos;

        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        const a = try self.stack.pop();

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

    fn else_then(self: *Interpreter, line: []const u8, end_pos: *usize) anyerror!void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "then");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];

        try self.lex(arg);
        end_pos.* = new_end_pos + 5;
    }

    fn compile_word(self: *Interpreter, line: []const u8, end_pos: *usize) !void {
        end_pos.* += 1;

        if (end_pos.* >= line.len) return error.Marker_Not_Found;

        const word_end = find_end_current_token(&line, end_pos.*);

        const word = line[end_pos.*..word_end];
        const owned_key = try self.allocator.dupe(u8, word);
        end_pos.* = word_end + 1;

        const definition_end = try find_end_marker(&line, end_pos.*, " ;");
        if (definition_end >= line.len) return error.Marker_Not_Found;
        const owned_stmnt = try self.allocator.dupe(u8, line[end_pos.* .. definition_end + 1]);

        try self.dictionary.user_words.put(owned_key, owned_stmnt);

        end_pos.* = definition_end + 2;
    }

    fn see(self: *Interpreter, line: []const u8, end_pos: *usize) !void {
        const key = std.mem.trim(u8, line[end_pos.*..], " \t\n");
        end_pos.* = line.len;

        if (self.dictionary.immediate_words.contains(key)) {
            try outw.print("definition: {any}\n", .{self.dictionary.immediate_words.get(key)});
            return;
        }

        if (self.dictionary.compiled_words.contains(key)) {
            try outw.print("definition: {any}\n", .{self.dictionary.compiled_words.get(key)});
            return;
        }

        if (self.dictionary.user_words.contains(key)) {
            const definition: []const u8 = self.dictionary.user_words.get(key) orelse "";
            try outw.print("definition: {s}\n", .{definition});
            return;
        }

        try outw.print("No word called {s}\n", .{key});
    }

    pub fn lex(self: *Interpreter, line: []const u8) anyerror!void {
        var pos: usize = 0;

        while (pos < line.len) {
            pos = skip_white_spaces(&line, pos);
            if (pos >= line.len) break;
            var end_pos = find_end_current_token(&line, pos);

            // Match token case insensitive except for .S
            var token_text: []const u8 = undefined;
            defer self.allocator.free(token_text);
            if (std.mem.eql(u8, line[pos..end_pos], ".S")) {
                token_text = try std.ascii.allocUpperString(self.allocator, line[pos..end_pos]);
            } else {
                token_text = try std.ascii.allocLowerString(self.allocator, line[pos..end_pos]);
            }

            if (self.dictionary.user_words.get(token_text)) |stmnt| {
                try self.lex(stmnt);
            } else if (self.dictionary.compiled_words.get(token_text)) |word| {
                try word(self, line, &end_pos);
            } else if (self.dictionary.immediate_words.get(token_text)) |word| {
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
