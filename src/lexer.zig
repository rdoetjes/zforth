const std = @import("std");
const outw = std.io.getStdOut().writer();

pub const lexer = struct {
    stack: std.ArrayList(f32),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*lexer {
        const self = try allocator.create(lexer);
        self.* = .{
            .stack = std.ArrayList(f32).init(allocator),
            .allocator = allocator,
        };
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
        if (std.mem.indexOf(u8, line.*[pos + 1 ..], marker)) |t_pos| {
            return pos + t_pos + 1;
        }

        return error.Marker_Not_Found;
    }

    fn check_if_number(line: *const []const u8) !bool {
        var t_pos: usize = 0;
        while (t_pos < line.*.len and line.*[t_pos] != ' ' and line.*[t_pos] != '\n') {
            if (line.*[t_pos] == '.') {
                t_pos += 1;
            } else if (line.*[t_pos] < '0' or line.*[t_pos] > '9') return error.Not_A_Number;
            {
                t_pos += 1;
            }
        }
        return true;
    }

    fn pop(self: *lexer) !f32 {
        if (self.stack.items.len == 0) {
            return error.Stack_Underflow;
        }
        const a = self.stack.pop();
        return a;
    }

    fn add(self: *lexer) !void {
        const b = self.stack.pop();
        const a = self.stack.pop();
        try self.stack.append(a + b);
    }

    fn mul(self: *lexer) !void {
        const a = self.stack.pop();
        const b = self.stack.pop();
        try self.stack.append(a * b);
    }

    fn div(self: *lexer) !void {
        const b = self.stack.pop();
        const a = self.stack.pop();
        try self.stack.append(a / b);
    }

    fn print_string(_: *lexer, line: []const u8, end_pos: *usize) !void {
        const new_end_pos = try find_end_marker(&line, end_pos.*, "\" ");
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        try outw.print("{s}", .{arg});
        end_pos.* = new_end_pos + 1;
    }

    pub fn lex(self: *lexer, line: []const u8) !void {
        var pos: usize = 0;

        while (pos < line.len) {
            pos = skip_white_spaces(&line, pos);
            if (pos >= line.len) break;
            var end_pos = find_end_current_token(&line, pos);

            // Match token
            const token_text = line[pos..end_pos];

            if (std.mem.eql(u8, token_text, ".\"")) {
                try print_string(self, line, &end_pos);
            } else if (std.mem.eql(u8, token_text, ".")) {
                try outw.print("{d}", .{self.stack.pop()});
            } else if (std.mem.eql(u8, token_text, "cr")) {
                try outw.print("\n", .{});
            } else if (std.mem.eql(u8, token_text, "+")) {
                try self.add();
            } else if (std.mem.eql(u8, token_text, "*")) {
                try self.mul();
            } else if (std.mem.eql(u8, token_text, "/")) {
                try self.div();
            } else {
                // Handle other token types or unknown tokens here
                if (try check_if_number(&line[pos..end_pos])) {
                    const number = try std.fmt.parseFloat(f32, token_text);
                    try self.stack.append(number);
                }
            }

            pos = end_pos;
        }
    }
};
