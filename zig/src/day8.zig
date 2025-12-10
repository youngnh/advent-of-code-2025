const std = @import("std");
const Reader = std.io.Reader;

const Point = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn dist(self: Point, other: Point) f32 {
        const dx = other.x - self.x;
        const x2 = dx * dx;
        const dy = other.y - self.y;
        const y2 = dy * dy;
        const dz = other.z - self.z;
        const z2 = dz * dz;

        const sum: f32 = @floatFromInt(x2 + y2 + z2);
        return std.math.sqrt(sum);
    }

    pub fn dist_d(self: Point, other: Point, dim: u8) f32 {
        const dx = other.x - self.x;
        const x2 = dx * dx;
        const dy = other.y - self.y;
        const y2 = dy * dy;
        const dz = other.z - self.z;
        const z2 = dz * dz;

        switch (dim) {
            1 => return dx,
            2 => return std.math.sqrt(x2 + y2),
            else => return std.math.sqrt(x2 + y2 + z2),
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const argv = try std.process.argsAlloc(allocator);

    if (argv.len < 2) {
        std.process.fatal("Expected input argument, but none given\n", .{});
    }

    const infile = try std.fs.cwd().openFile(argv[1], .{ .mode = .read_only });
    defer infile.close();

    var infile_reader = infile.reader(try allocator.alloc(u8, 20 * 1024));
    const input = &infile_reader.interface;

    var i: usize = 0;
    var points: [256]Point = undefined;
    while (input.peekByte()) |_| {
        points[i] = try readPoint(input);
        i += 1;
    } else |_| {
        // end of input
    }
    std.debug.print("Read {d} points\n", .{ i });
    const idxs = closest_pair(points[0..i]);
    const p = points[idxs[0]];
    const q = points[idxs[1]];
    const d = p.dist(q);
    std.debug.print("Closest points: {d},{d},{d} and {d},{d},{d} at dist {d}\n", .{ p.x, p.y, p.z, q.x, q.y, q.z, d });
}

pub fn readPoint(input: *Reader) !Point {
    var p: Point = undefined;
    var num_str = try input.takeDelimiterInclusive(',');
    p.x = try std.fmt.parseInt(i32, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive(',');
    p.y = try std.fmt.parseInt(i32, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive('\n');
    p.z = try std.fmt.parseInt(i32, num_str[0..num_str.len - 1], 10);

    return p;
}

// returns the indexes of the two closest points
pub fn closest_pair(points: []Point) [2]usize {
    var result: [2]usize = undefined;
    var min_dist: f32 = std.math.floatMax(f32);
    for (0..points.len) |p| {
        for (p + 1..points.len) |q| {
            const d = points[p].dist(points[q]);
            if (d < min_dist) {
                result[0] = p;
                result[1] = q;
                min_dist = d;
            }
        }
    }
    return result;
}
