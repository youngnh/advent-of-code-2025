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

    const startLine = try input.takeDelimiterInclusive('\n');
    const width = startLine.len - 1;
    var start_idx: usize = 0;
    while (start_idx < startLine.len and startLine[start_idx] != 'S') {
        start_idx += 1;
    }
    std.debug.print("Line width={d} start={d}\n", .{ width, start_idx });

    var linebuf: [1024][]u8 = undefined;
    var cachedbuf: [256 * 256]?u64 = [_]?u64{null} ** (256 * 256);
    linebuf[0] = startLine;
    var nlines: usize = 1;
    while (input.peekByte()) |_| {
        const fullline = try input.takeDelimiterInclusive('\n');
        linebuf[nlines] = fullline[0..width];
        nlines += 1;
    } else |_| {
        // end of input
    }
    std.debug.print("nlines={d}\n", .{ nlines });
    const buf = linebuf[0..nlines];
    const cache = cachedbuf[0..(nlines * width)];

    const answer: u64 = timelines(start_idx, 1, buf, cache, width);
    std.debug.print("Answer: {d}\n", .{ answer });
}

pub fn timelines(scol: usize, srow: usize, buf: [][]u8, cache: []?u64, width: usize) u64 {
    if (srow >= buf.len) {
        return 1;
    }

    std.debug.print("timelines: c={d} r={d}", .{ scol, srow });
    if (cache[srow * width + scol]) |value| {
        std.debug.print("...cache hit\n", .{});
        return value;
    }
    std.debug.print("\n", .{});

    const line = buf[srow];

    var result: u64 = undefined;
    if (line[scol] == '^') {
        result = 0;
        if (scol >= 1) {
            result += timelines(scol - 1, srow + 1, buf, cache, width);
        }
        if (scol + 1 < line.len) {
            result += timelines(scol + 1, srow + 1, buf, cache, width);
        }
    } else {
        result = timelines(scol, srow + 1, buf, cache, width);
    }
    cache[srow * width + scol] = result;
    return result;
}
