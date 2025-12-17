const std = @import("std");
const Reader = std.io.Reader;

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
    const input = &infile_reader.interface;

    var i: usize = 0;
    var points_arr: [1024]Point = undefined;
    while (input.peekByte()) |_| {
        points_arr[i] = try readPoint(input);
        i += 1;
    } else |_| {
        // end of input
    }
    const points: []Point = points_arr[0..i];
    std.debug.print("Read {d} points\n", .{ points.len });
}

const Point = struct {
    x: i64,
    y: i64,
};

pub fn readPoint(input: *Reader) !Point {
    var num_str = try input.takeDelimiterInclusive(',');
    const x = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive('\n');
    const y = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    return Point{ .x = x, .y = y };
}
