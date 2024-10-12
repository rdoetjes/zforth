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

    fn check_if_number(line: *const []const u8) bool {
        var t_pos: usize = 0;
        while (t_pos < line.*.len and line.*[t_pos] != ' ' and line.*[t_pos] != '\n') {
            if (line.*[t_pos] == '.') {
                t_pos += 1;
            } else if (line.*[t_pos] < '0' or line.*[t_pos] > '9') {
                outw.print("Invalid number\n", .{}) catch {};
            } else {
                t_pos += 1;
            }
        }
        return true;
    }

    fn pop(self: *lexer) f32 {
        if (self.stack.items.len == 0) {
            outw.print("Stack underflow\n", .{}) catch {};
            return 0;
        }
        const a = self.pop();
        return a;
    }

    fn add(self: *lexer) void {
        const b = self.pop();
        const a = self.pop();
        self.stack.append(a + b) catch {
            std.debug.panic("out of memory", .{});
        };
    }

    fn mul(self: *lexer) void {
        const a = self.pop();
        const b = self.pop();
        self.stack.append(a * b) catch {
            std.debug.panic("out of memory", .{});
        };
    }

    fn div(self: *lexer) void {
        const b = self.pop();
        const a = self.pop();
        if (b == 0) {
            outw.print("Division by zero\n", .{}) catch {};
            return;
        }
        self.stack.append(a / b) catch {
            std.debug.panic("out of memory", .{});
        };
    }

    fn print_string(_: *lexer, line: []const u8, end_pos: *usize) void {
        const new_end_pos = find_end_marker(&line, end_pos.*, "\"") catch {
            outw.print("String without end \" marker\n", .{}) catch {};
            return;
        };
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];
        outw.print("{s}", .{arg}) catch {};
        end_pos.* = new_end_pos + 1;
    }

    fn do_number(self: *lexer, line: []const u8, end_pos: *usize) void {
        const new_end_pos = find_end_marker(&line, end_pos.*, "loop") catch {
            outw.print("do without loop\n", .{}) catch {};
            return;
        };
        const start_pos = end_pos.*;
        const arg = line[start_pos + 1 .. new_end_pos];

        const b: usize = @intFromFloat(self.stack.pop());
        const a: usize = @intFromFloat(self.stack.pop());
        std.debug.print("a: {d} b: {d} arg: {s} \n", .{ a, b, arg });
        for (a..b) |_| {
            self.lex(arg);
        }
        end_pos.* = new_end_pos + 5;
    }

    pub fn lex(self: *lexer, line: []const u8) void {
        var pos: usize = 0;

        while (pos < line.len) {
            pos = skip_white_spaces(&line, pos);
            if (pos >= line.len) break;
            var end_pos = find_end_current_token(&line, pos);

            // Match token
            const token_text = line[pos..end_pos];

            if (std.mem.eql(u8, token_text, ".\"")) {
                print_string(self, line, &end_pos);
            } else if (std.mem.eql(u8, token_text, "do")) {
                do_number(self, line, &end_pos);
            } else if (std.mem.eql(u8, token_text, ".")) {
                outw.print("{d}", .{self.stack.pop()}) catch {};
            } else if (std.mem.eql(u8, token_text, "cr")) {
                outw.print("\n", .{}) catch {};
            } else if (std.mem.eql(u8, token_text, "+")) {
                self.add();
            } else if (std.mem.eql(u8, token_text, "*")) {
                self.mul();
            } else if (std.mem.eql(u8, token_text, "/")) {
                self.div();
            } else {
                // Handle other token types or unknown tokens here
                std.debug.print("Unknown token: {s}\n", .{token_text});
                if (check_if_number(&line[pos..end_pos])) {
                    const number = std.fmt.parseFloat(f32, token_text) catch {
                        std.debug.print("Invalid number\n", .{});
                        continue;
                    };
                    self.stack.append(number) catch {
                        std.debug.panic("out of memory", .{});
                    };
                }
            }

            pos = end_pos;
        }
    }
};
