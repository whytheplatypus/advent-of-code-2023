const std = @import("std");

pub fn main() !void {
    // read the file at input.txt line by line
    const file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var power: i32 = 0;
    var sum: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const min_sample = try game_min_set(line);
        power += min_sample.power();

        const id = is_game_possible(line) catch {
            //std.debug.print("error: {} for {s}\n", .{ err, line });
            continue;
        };
        sum += id;
    }
    std.debug.print("sum: {}\n", .{sum});
    std.debug.print("power: {}\n", .{power});
}
const Sample = struct {
    red: i32,
    green: i32,
    blue: i32,
    fn parse_sample(input: []const u8) !Sample {
        // split input on commas
        var s = Sample{ .red = 0, .green = 0, .blue = 0 };
        var it = std.mem.split(u8, input, ",");
        while (it.next()) |x| {
            var pecies = std.mem.split(u8, x, " ");
            if (std.mem.eql(u8, pecies.peek().?, "")) {
                _ = pecies.next();
            }
            const val = pecies.next().?;
            const count = try std.fmt.parseInt(i32, val, 10);
            const color = pecies.next().?;
            if (std.mem.eql(u8, color, "red")) {
                s.red = count;
            } else if (std.mem.eql(u8, color, "green")) {
                s.green = count;
            } else if (std.mem.eql(u8, color, "blue")) {
                s.blue = count;
            } else {
                return error.Bad;
            }
        }
        return s;
    }

    fn is_possible(self: Sample, red: i32, green: i32, blue: i32) bool {
        //std.debug.print("red: {}, green: {}, blue: {}\n", .{ self.red, self.green, self.blue });
        return red >= self.red and green >= self.green and blue >= self.blue;
    }

    fn power(self: Sample) i32 {
        std.debug.print("red: {}, green: {}, blue: {}\n", .{ self.red, self.green, self.blue });
        const p = self.red * self.green * self.blue;
        std.debug.print("power: {}\n", .{p});
        return p;
    }
};

test "parse_sample" {
    var s = try Sample.parse_sample("1 red, 2 green, 3 blue");
    try std.testing.expectEqual(s.red, 1);
    try std.testing.expectEqual(s.green, 2);
    try std.testing.expectEqual(s.blue, 3);
}

fn is_game_possible(input: []const u8) !i32 {
    var it = std.mem.split(u8, input, ":");
    const game_and_id = it.next().?;
    const rest = it.next().?;

    var game_parts = std.mem.split(u8, game_and_id, " ");
    _ = game_parts.next();
    const id = std.fmt.parseInt(i32, game_parts.next().?, 10);

    var raw_samples = std.mem.split(u8, rest, ";");
    while (raw_samples.next()) |raw_sample| {
        const sample = try Sample.parse_sample(raw_sample);
        if (!sample.is_possible(12, 13, 14)) {
            return error.NotPossible;
        }
    }
    return id;
}

fn game_min_set(input: []const u8) !Sample {
    var it = std.mem.split(u8, input, ":");
    _ = it.next().?;
    const rest = it.next().?;
    var min_sample = Sample{ .red = 0, .green = 0, .blue = 0 };
    var raw_samples = std.mem.split(u8, rest, ";");
    while (raw_samples.next()) |raw_sample| {
        const sample = try Sample.parse_sample(raw_sample);
        if (sample.red > min_sample.red) {
            min_sample.red = sample.red;
        }
        if (sample.green > min_sample.green) {
            min_sample.green = sample.green;
        }
        if (sample.blue > min_sample.blue) {
            min_sample.blue = sample.blue;
        }
    }
    return min_sample;
}

test "game is possible" {
    const input = "Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red";
    try std.testing.expectError(error.NotPossible, is_game_possible(input));

    const input2 = "Game 3: 8 green, 6 blue, 12 red; 5 blue, 4 red, 13 green; 5 green, 1 red";
    try std.testing.expectEqual(@as(i32, 3), try is_game_possible(input2));
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
