const std = @import("std");

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

    var infile_reader = infile.reader(try allocator.alloc(u8, 20 * 1024));
    var input = &infile_reader.interface;

    try input.fillMore();
    const buf = input.buffered();

    var i: usize = 0;
    var width: u32 = 0;
    var height: u32 = 0;
    while (i < buf.len) {
        if (buf[i] == '\n') {
            if (width == 0) {
                width = @intCast(i + 1);
            }
            height += 1;
        }
        i += 1;
    }

    var c: usize = 0;
    var col_total: u64 = undefined;
    var op: u8 = undefined;
    var answer: u64 = 0;
    while (c < width - 1) {
        const lastchar = buf[width * (height - 1) + c];
        if (lastchar == '*') {
            op = lastchar;
            col_total = 1;
        } else if (lastchar == '+') {
            op = lastchar;
            col_total = 0;
        }
        const n = readColNum(c, width, height, buf);
        if (n == 0) {
            std.debug.print("Col total {c} {d}\n", .{ op, col_total });
            answer += col_total;
        } else {
            if (op == '*') {
                col_total *= n;
            } else if (op == '+') {
                col_total += n;
            } else {
                std.process.fatal("Unknown operator {c}\n", .{ op });
            }
            std.debug.print("col={d} n={d}\n", .{ c, n });
        }
        c += 1;
    }
    answer += col_total;

    std.debug.print("Answer {d}\n", .{ answer });
}

pub fn readColNum(c: usize, width: u32, height: u32, buf: []u8) u64 {
    var n: u64 = 0;
    var r: usize = 0;
    while (r < height - 1) {
        const idx = width * r + c;
        if (buf[idx] != ' ') {
            const digit: u64 = buf[idx] - '0';
            n *= 10;
            n += digit;
        }
        r += 1;
    }

    return n;
}
