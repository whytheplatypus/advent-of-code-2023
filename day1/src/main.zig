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

fn is_string_digit(input: []const u8) !?i32 {
    std.debug.print("is_string_digit: {s}\n", .{input});
    const word_map = std.ComptimeStringMap(i32, .{
        .{ "one", 1 },
        .{ "two", 2 },
        .{ "three", 3 },
        .{ "four", 4 },
        .{ "five", 5 },
        .{ "six", 6 },
        .{ "seven", 7 },
        .{ "eight", 8 },
        .{ "nine", 9 },
    });

    return word_map.get(input);
}

test "is string digit" {
    const actual = try is_string_digit("one");
    try std.testing.expectEqual(@as(i32, 1), actual.?);
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
    for (0.., input) |i, c| {
        if (std.fmt.parseInt(i32, &[1]u8{c}, 10)) |n| {
            return n;
        } else |_| {
            //try a chunk of 3
            if (i + 2 < input.len) {
                if (try is_string_digit(input[i .. i + 3])) |n| {
                    return n;
                }
            }
            //try a chunk of 4
            if (i + 3 < input.len) {
                if (try is_string_digit(input[i .. i + 4])) |n| {
                    return n;
                }
            }
            //try a chunk of 5
            if (i + 4 < input.len) {
                if (try is_string_digit(input[i .. i + 5])) |n| {
                    return n;
                }
            }
        }
    }
    return error.InvalidParam;
}

test "find first" {
    const cases = [_]TestCase{
        TestCase{ .input = "1abc2", .expected = 1 },
        TestCase{ .input = "two1abc2", .expected = 2 },
    };
    for (cases) |case| {
        const actual = try find_first(case.input);
        try std.testing.expectEqual(@as(i32, case.expected), actual);
    }
}

fn find_last(input: []const u8) !i32 {
    var i: usize = input.len - 1;
    while (i >= 0) : (i -= 1) {
        const c = input[i];
        if (std.fmt.parseInt(i32, &[1]u8{c}, 10)) |n| {
            return n;
        } else |_| {
            //try a chunk of 3
            if (i > 1) {
                if (try is_string_digit(input[i - 2 .. i + 1])) |n| {
                    return n;
                }
            }
            //try a chunk of 4
            if (i > 2) {
                if (try is_string_digit(input[i - 3 .. i + 1])) |n| {
                    return n;
                }
            }
            //try a chunk of 5
            if (i > 3) {
                if (try is_string_digit(input[i - 4 .. i + 1])) |n| {
                    return n;
                }
            }
        }
    }
    return error.InvalidParam;
}
const TestCase = struct {
    input: []const u8,
    expected: i32,
};

test "find last" {
    const cases = [_]TestCase{
        TestCase{ .input = "1abc2", .expected = 2 },
        TestCase{ .input = "7pqrstsixteen", .expected = 6 },
    };

    for (cases) |case| {
        const actual = try find_last(case.input);
        try std.testing.expectEqual(@as(i32, case.expected), actual);
    }
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
        std.debug.print("line: {s} sum: {d}\n", .{ line, lineSum });
        sum += lineSum;
    }
    return sum;
}

test "calibration values sum" {
    const actual = try sum_calibration_values(std.testing.allocator, test_input);
    try std.testing.expectEqual(@as(i32, 142), actual);
}

test "calibration values sum 2" {
    const test_input2 =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    const actual = try sum_calibration_values(std.testing.allocator, test_input2);
    try std.testing.expectEqual(@as(i32, 281), actual);
}
