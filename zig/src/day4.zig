const std = @import("std");

pub fn n_around(r: usize, c: usize, grid: [][]u8) u8 {
    const offsets = [3]i32{ -1, 0, 1 };

    var result: u8 = 0;
    for (offsets) |dy| {
        var ry: i32 = @intCast(r);
        ry += dy;
        if (ry < 0 or ry >= grid.len) {
            continue;
        }
        const yy: usize = @intCast(ry);

        for (offsets) |dx| {
            if (dy == 0 and dx == 0) {
                continue;
            }

            var rx: i32 = @intCast(c);
            rx += dx;
            if (rx < 0 or rx >= grid[yy].len) {
                continue;
            }
            const xx: usize = @intCast(rx);

            if (grid[yy][xx] == '@') {
                result += 1;
            }
        }
    }
    return result;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const argv = try std.process.argsAlloc(allocator);

    if (argv.len < 2) {
      std.process.fatal("Expected input argument, but none given", .{});
    }

    const infile = try std.fs.cwd().openFile(argv[1], .{ .mode = .read_only });
    defer infile.close();

    var infile_reader = infile.reader(try allocator.alloc(u8, 64 * 1024));
    var input = &infile_reader.interface;

    var lines: [1024][]u8 = undefined;
    var i: usize = 0;
    while (true) {
        if (input.takeDelimiterExclusive('\n')) |line| {
            lines[i] = line;
            _ = try input.takeByte();
            i += 1;
        } else |_| {
            break;
        }
    }

    std.debug.print("Read {d} lines\n", .{ i });
    const grid: [][]u8 = lines[0..i];

    var answer: u32 = 0;
    for (grid, 0..) |line, row| {
        for (line, 0..) |ch, col| {
            if (ch == '@' and n_around(row, col, grid) < 4) {
                answer += 1;
            }
        }
    }

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    for (grid, 0..) |line, row| {
        for (line, 0..) |ch, col| {
            if (ch == '@') {
                const n = n_around(row, col, grid);
                if (n < 4) {
                    grid[row][col] = 'x';
                } else {
                    std.debug.print("{d},{d} surrounded by {d}\n", .{ row, col, n });
                    grid[row][col] = '0' + n;
                }
            }
        }
    }
    for (grid) |line| {
        try stdout.print("{s}\n", .{ line });
    }

    try stdout.print("\nAnswer: {d}\n", .{ answer });
    try stdout.flush();
}
