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

    var max_area: u64 = 0;
    var final_p: Point = undefined;
    var final_q: Point = undefined;
    for (points[0..points.len - 1]) |p| {
        for (points[1..points.len]) |q| {
            const a: Point = .{ .x = q.x, .y = p.y };
            if (!a.interior(points)) {
                std.debug.print("{d},{d} is not interior\n\n", .{ a.x, a.y });
                continue;
            }
            const b: Point = .{ .x = p.x, .y = q.y };
            if (!b.interior(points)) {
                std.debug.print("{d},{d} is not interior\n\n", .{ b.x, b.y });
                continue;
            }

            if (intersects(p, a, points)) |seg| {
                std.debug.print("{d},{d} to {d},{d} crosses segment {d},{d} to {d},{d}\n\n", .{ p.x, p.y, a.x, a.y, seg[0].x, seg[0].y, seg[1].x, seg[1].y });
                continue;
            }
            if (intersects(a, q, points)) |seg| {
                std.debug.print("{d},{d} to {d},{d} crosses segment {d},{d} to {d},{d}\n\n", .{ a.x, a.y, q.x, q.y, seg[0].x, seg[0].y, seg[1].x, seg[1].y });
                continue;
            }
            if (intersects(q, b, points)) |seg| {
                std.debug.print("{d},{d} to {d},{d} crosses segment {d},{d} to {d},{d}\n\n", .{ q.x, q.y, b.x, b.y, seg[0].x, seg[0].y, seg[1].x, seg[1].y });
                continue;
            }
            if (intersects(b, p, points)) |seg| {
                std.debug.print("{d},{d} to {d},{d} crosses segment {d},{d} to {d},{d}\n\n", .{ b.x, b.y, p.x, p.y, seg[0].x, seg[0].y, seg[1].x, seg[1].y });
                continue;
            }
            const area = area_of(p, q);
            std.debug.print("Corners: {d},{d} and {d},{d} no intersections, area={d}\n\n", .{ p.x, p.y, q.x, q.y, area });
            if (area > max_area) {
                max_area = area;
                final_p = p;
                final_q = q;
            }
        }
    }

    std.debug.print("Final corners {d},{d} {d},{d}\n", .{ final_p.x, final_p.y, final_q.x, final_q.y });
    std.debug.print("Answer: {d}\n", .{ max_area });
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

pub fn intersects(p: Point, q: Point, polygon: []Point) ?[2]Point {
    var s1 = polygon[0];
    var s2: Point = undefined;
    var i: usize = 1;
    while (i <= polygon.len) {
        s2 = polygon[i % polygon.len];

        // horizontal pq intersects vertical segment
        if (p.y == q.y) {
            if (s1.x == s2.x) {
                if (@min(s1.y, s2.y) < p.y and p.y < @max(s1.y, s2.y)) {
                    if (@min(p.x, q.x) < s1.x and s1.x < @max(p.x, q.x)) {
                        return .{ s1, s2 };
                    }
                }
            }
        }

        // vertical pq intersects horizontal segment
        if (p.x == q.x) {
            if (s1.y == s2.y) {
                if (@min(s1.x, s2.x) < p.x and p.x < @max(s1.x, s2.x)) {
                    if (@min(p.y, q.y) < s1.y and s1.y < @max(p.y, q.y)) {
                        return .{ s1, s2 };
                    }
                }
            }
        }

        s1 = s2;
        i += 1;
    }
    return null;
}

pub fn readPoint(input: *Reader) !Point {
    var num_str = try input.takeDelimiterInclusive(',');
    const x = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive('\n');
    const y = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    return Point{ .x = x, .y = y };
}

pub fn area_of(p: Point, q: Point) u64 {
    return @abs(p.x - q.x + 1) * @abs(p.y - q.y + 1);
}
