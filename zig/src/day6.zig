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
    const offset = width * (height - 1);
    var c: usize = 0;
    while (c + offset < buf.len) {
        std.debug.print("C={d} op={c}\n", .{ c, buf[c + offset] });
        var w: usize = c + 1;
        while (w + offset < buf.len and buf[w + offset] == ' ') {
            w += 1;
        }
        w = w - c;
        std.debug.print("w: {d}\n", .{ w });
        var r: usize = 0;
        var col_total: u64 = undefined;
        if (buf[c + offset] == '*') {
            col_total = 1;
        } else if (buf[c + offset] == '+') {
            col_total = 0;
        } else if (buf[c + offset] == '\n') {
            break;
        } else {
            std.process.fatal("Unknown operator {c}\n", .{ buf[c + offset] });
        }
        while (r < height - 1) {
            const a = width * r + c;
            const b = a + w;
            const numstr = std.mem.trim(u8, buf[a..b], " \n");
            std.debug.print("Parsing '{s}'\n", .{ numstr });
            const n = try std.fmt.parseInt(u32, numstr, 10);
            if (buf[c + offset] == '*') {
                col_total *= n;
            } else if (buf[c + offset] == '+') {
                col_total += n;
            } else {
                std.process.fatal("Unknown operator {c}\n", .{ buf[c + offset] });
            }
            r += 1;
        }
        std.debug.print("Col total {d}\n", .{ col_total });
        answer += col_total;
        c += w;
    }

    std.debug.print("Answer: {d}\n", .{ answer });
}
