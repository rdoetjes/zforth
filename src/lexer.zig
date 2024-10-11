const std = @import("std");

const TokenType = enum {
    PUSH,
    POP,
    ADD,
    SUB,
    MUL,
    DIV,
    NUMBER,
    DOT,
    DOT_S,
    DOT_CAP_S,
    DOT_DOUBLE_QUOTE,
    EOF,
};

const Token = struct {
    type: TokenType,
    start_pos: usize,
    text: []const u8,

    pub fn init(token_type: TokenType, start_pos: usize, text: []const u8) Token {
        return Token{
            .type = token_type,
            .start_pos = start_pos,
            .text = text,
        };
    }
};

pub fn print_tokens(tokens: *std.ArrayList(Token)) void {
    for (tokens.*.items) |token| {
        std.debug.print("{any} {s} {d}\n", .{ token.type, token.text, token.start_pos });
    }
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

pub fn lex(allocator: std.mem.Allocator, line: []const u8) !*std.ArrayList(Token) {
    var tokens = try std.ArrayList(Token).initCapacity(allocator, 10);

    var pos: usize = 0;
    while (pos < line.len) {
        pos = skip_white_spaces(&line, pos);
        if (pos >= line.len) break;
        const end_pos = find_end_current_token(&line, pos);

        // Match token
        const token_text = line[pos..end_pos];
        if (std.mem.eql(u8, token_text, "PUSH")) {
            try tokens.append(Token.init(TokenType.PUSH, pos, token_text));
        } else if (std.mem.eql(u8, token_text, ".\"")) {
            try tokens.append(Token.init(TokenType.DOP_DOUBLE_QUOTE, pos, token_text));
        } else {
            // Handle other token types or unknown tokens here
        }

        pos = end_pos;
    }

    return &tokens;
}
