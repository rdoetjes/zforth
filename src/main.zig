const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_alloc = gpa.allocator();
const interpreter = @import("interpreter.zig");
const outw = std.io.getStdOut().writer();
const inr = std.io.getStdIn().reader();

var system_words: *std.StringHashMap(interpreter.OpFunction) = undefined;
var my_words: *std.StringHashMap(*interpreter.Op) = undefined;

var arg_stack: *std.ArrayList(f32) = undefined;
var op_stack: *std.ArrayList(*interpreter.Op) = undefined;

fn prompt() void {
    outw.print("ok\n", .{}) catch {
        std.debug.print("failed to print prompt", .{});
    };
}

fn welcome() void {
    outw.print("small lean forth in zig\n", .{}) catch {
        std.debug.print("failed to print welcome", .{});
    };
}

fn repl() void {
    welcome();
    while (true) {
        prompt();
        const line = inr.readUntilDelimiterOrEofAlloc(gpa_alloc, '\n', 4096) catch |err| {
            outw.print("{}\n", .{err}) catch {};
            continue;
        } orelse {
            outw.print("End of input reached\n", .{}) catch {};
            break;
        };

        const line_cleaned = std.mem.trim(u8, line, " \t\n");

        interpreter.parse(line_cleaned) catch |err| {
            op_stack.*.clearRetainingCapacity();
            outw.print("{}\n", .{err}) catch {
                std.debug.panic("failed to print error message", .{});
            };
        };

        interpreter.compile() catch |err| {
            op_stack.*.clearRetainingCapacity();
            outw.print("{}\n", .{err}) catch {
                std.debug.panic("failed to print error message", .{});
            };
        };
        gpa_alloc.free(line);
    }
}

pub fn main() !void {
    var l_arg_stack = std.ArrayList(f32).init(gpa_alloc);
    defer l_arg_stack.deinit();
    arg_stack = &l_arg_stack;
    arg_stack.*.clearRetainingCapacity();

    var l_op_stack = std.ArrayList(*interpreter.Op).init(gpa_alloc);
    defer l_op_stack.deinit();
    op_stack = &l_op_stack;
    op_stack.*.clearRetainingCapacity();

    var l_my_words = std.StringHashMap(*interpreter.Op).init(gpa_alloc);
    defer l_my_words.deinit();
    my_words = &l_my_words;

    var l_system_words = std.StringHashMap(interpreter.OpFunction).init(gpa_alloc);
    defer l_system_words.deinit();
    system_words = &l_system_words;

    try interpreter.init_operations(&l_system_words, &l_arg_stack, &l_op_stack, &l_my_words);

    repl();
}
