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
    var start_idx: usize = 0;
    while (start_idx < startLine.len and startLine[start_idx] != 'S') {
        start_idx += 1;
    }
    std.debug.print("Line length={d} start={d}\n", .{ startLine.len, start_idx });

    var linebuf: [1024][]u8 = undefined;
    linebuf[0] = startLine;
    var nlines: usize = 1;
    while (input.peekByte()) |_| {
        const fullline = try input.takeDelimiterInclusive('\n');
        linebuf[nlines] = fullline[0..startLine.len - 1];
        nlines += 1;
    } else |_| {
        // end of input
    }
    const buf = linebuf[0..nlines];

    const answer: u64 = timelines(start_idx, 1, buf);
    std.debug.print("Answer: {d}\n", .{ answer });
}

pub fn timelines(scol: usize, srow: usize, buf: [][]u8) u64 {
    if (srow >= buf.len) {
        return 1;
    }

    const line = buf[srow];

    var result: u64 = undefined;
    if (line[scol] == '^') {
        result = 0;
        if (scol >= 1) {
            result += timelines(scol - 1, srow + 1, buf);
        }
        if (scol + 1 < line.len) {
            result += timelines(scol + 1, srow + 1, buf);
        }
    } else {
        result = timelines(scol, srow + 1, buf);
    }
    return result;
}
