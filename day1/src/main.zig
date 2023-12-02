const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    const mb = (1 << 10) << 10;
    const file_contents = try file.readToEndAlloc(allocator, 1 * mb);
    const result = try sum_calibration_values(allocator, file_contents);
    std.debug.print("result: {d}\n", .{result});
}

fn split_input(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var result = std.ArrayList([]const u8).init(allocator);
    defer result.deinit();
    var start: usize = 0;
    for (0.., input) |i, c| {
        if (c == '\n') {
            try result.append(input[start..i]);
            start = i + 1;
        }
    }
    if (start != 0) {
        try result.append(input[start..]);
    }
    return result.toOwnedSlice();
}

const test_input =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
;

test "split input" {
    const actual = try split_input(std.testing.allocator, test_input);
    // takes care of the memory leak..
    defer std.testing.allocator.free(actual);
    const expected = [_][]const u8{
        "1abc2",
        "pqr3stu8vwx",
        "a1b2c3d4e5f",
        "treb7uchet",
    };
    try std.testing.expectEqual(expected.len, actual.len);

    for (0.., actual) |i, line| {
        std.debug.print("compairing: {s} and {s}\n", .{ line, expected[i] });
        try std.testing.expectEqualSlices(u8, expected[i], line);
    }
}

fn find_first(input: []const u8) !i32 {
    for (input) |c| {
        if (std.fmt.parseInt(i32, &[1]u8{c}, 10)) |n| {
            return n;
        } else |_| {}
    }
    return error.InvalidParam;
}

test "find first" {
    const input = "1abc2";
    const actual = try find_first(input);
    try std.testing.expectEqual(@as(i32, 1), actual);
}

fn find_last(input: []const u8) !i32 {
    var i: usize = input.len - 1;
    while (i >= 0) : (i -= 1) {
        const c = input[i];
        if (std.fmt.parseInt(i32, &[1]u8{c}, 10)) |n| {
            return n;
        } else |_| {}
    }
    return error.InvalidParam;
}

test "find last" {
    const input = "1abc2";
    const actual = try find_last(input);
    try std.testing.expectEqual(@as(i32, 2), actual);
}

fn compute_line(allocator: std.mem.Allocator, input: []const u8) !i32 {
    const first = try find_first(input);
    const last = try find_last(input);
    const resultString = try std.fmt.allocPrint(allocator, "{d}{d}", .{ first, last });
    defer allocator.free(resultString);
    return try std.fmt.parseInt(i32, resultString, 10);
}

test "compute line" {
    const input = "1abc2";
    const actual = try compute_line(std.testing.allocator, input);
    try std.testing.expectEqual(@as(i32, 12), actual);
}

fn sum_calibration_values(allocator: std.mem.Allocator, input: []const u8) !i32 {
    const lines = try split_input(allocator, input);
    defer allocator.free(lines);
    var sum: i32 = 0;
    for (lines) |line| {
        const lineSum = try compute_line(allocator, line);
        sum += lineSum;
    }
    return sum;
}

test "calibration values sum" {
    const actual = try sum_calibration_values(std.testing.allocator, test_input);
    try std.testing.expectEqual(@as(i32, 142), actual);
}
