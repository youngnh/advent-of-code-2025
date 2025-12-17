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

    for (points[0..points.len - 1]) |p| {
        for (points[1..points.len]) |q| {
            std.debug.print("{d},{d} Interior? {}\n", .{ p.x, p.y, p.interior(points) });
            const a: Point = .{ .x = q.x, .y = p.y };
            std.debug.print("{d},{d} Interior? {}\n", .{ a.x, a.y, a.interior(points) });
            std.debug.print("{d},{d} Interior? {}\n", .{ q.x, q.y, q.interior(points) });
            const b: Point = .{ .x = p.x, .y = q.y };
            std.debug.print("{d},{d} Interior? {}\n\n", .{ b.x, b.y, b.interior(points) });
        }
    }
}

const Point = struct {
    x: i64,
    y: i64,

    pub fn interior(p: Point, polygon: []Point) bool {
        var s1 = polygon[0];
        var s2: Point = undefined;
        var i: usize = 1;
        var count: u32 = 0;
        while (i <= polygon.len) {
            s2 = polygon[i % polygon.len];

            // is a vertex
            if (p.x == s1.x and p.y == s1.y) {
                return true;
            }

            // is between two vertices of a horizontal line
            if (s1.y == s2.y) {
                if (p.y == s1.y) {
                    if (@min(s1.x, s2.x) <= p.x and p.x <= @max(s1.x, s2.x)) {
                        return true;
                    }
                }
            }

            // is interior (projection crosses an odd # of vertical lines)
            if (s1.x == s2.x) {
                if (@min(s1.y, s2.y) < p.y and p.y <= @max(s1.y, s2.y)) {
                    if (p.x <= s1.x) {
                        count += 1;
                    }
                }
            }

            s1 = s2;
            i += 1;
        }

        return count % 2 == 1;
    }
};

pub fn readPoint(input: *Reader) !Point {
    var num_str = try input.takeDelimiterInclusive(',');
    const x = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive('\n');
    const y = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    return Point{ .x = x, .y = y };
}
