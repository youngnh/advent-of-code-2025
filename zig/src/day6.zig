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

    var answer: u64 = 0;
    var c: usize = 0;
    while (c < width - 1) {
        var col_total: u64 = undefined;
        const op = buf[width * (height - 1) + c];
        if (op == '*') {
            col_total = 1;
        } else if (op == '+') {
            col_total = 0;
        } else {
            std.process.fatal("Unknown operator {c}\n", .{ op });
        }

        var r: usize = 0;
        while (r < height - 1) {
            const n = try readColNum(c, r, width, buf);
            if (op == '*') {
                col_total *= n;
            } else {
                col_total += n;
            }
            r += 1;
        }
        std.debug.print("Col total {d}\n", .{ col_total });
        answer += col_total;

        // move to next op
        c += 1;
        while (buf[width * (height - 1) + c] == ' ') {
            c += 1;
        }
    }

    std.debug.print("Answer: {d}\n", .{ answer });
}

pub fn readColNum(c: usize, r: usize, width: u32, buf: []u8) !u64 {
    var s: usize = width * r + c;
    // skip leading whitespace
    while (buf[s] == ' ') {
        s += 1;
    }
    var x: usize = s;
    // read until trailing whitespace
    while (buf[x] != ' ' and buf[x] != '\n') {
        x += 1;
    }
    // parse slice
    std.debug.print("Parsing '{s}'\n", .{ buf[s..x] });
    return std.fmt.parseInt(u64, buf[s..x], 10);
}
