const std = @import("std");
const Reader = std.io.Reader;


const Point = struct {
    x: i64,
    y: i64,
    z: i64,

    circuit: u32 = 0,

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
    var points_arr: [1024]Point = undefined;
    while (input.peekByte()) |_| {
        points_arr[i] = try readPoint(input);
        i += 1;
    } else |_| {
        // end of input
    }
    const points = points_arr[0..i];
    std.debug.print("Read {d} points\n", .{ points.len });

    var next_circuit: u32 = 1;
    var counts_arr = [_]u32{0} ** 1024;
    var min_dist: f32 = undefined;
    var max_count: u32 = 0;
    var last_pair: [2]*Point = undefined;
    while (max_count < points.len) {
        if (closest_pair(points, &min_dist)) |idxs| {
            var p = &points[idxs[0]];
            var q = &points[idxs[1]];

            if (p.circuit == 0 and q.circuit == 0) {
                p.circuit = next_circuit;
                q.circuit = next_circuit;
                counts_arr[next_circuit] += 2;
                if (counts_arr[next_circuit] > max_count) {
                    max_count = counts_arr[next_circuit];
                    last_pair[0] = p;
                    last_pair[1] = q;
                }
                next_circuit += 1;
            } else if (p.circuit == q.circuit) {
                // already connected
            } else if (p.circuit == 0) {
                p.circuit = q.circuit;
                counts_arr[p.circuit] += 1;
                if (counts_arr[p.circuit] > max_count) {
                    max_count = counts_arr[p.circuit];
                    last_pair[0] = p;
                    last_pair[1] = q;
                }
            } else if (q.circuit == 0) {
                q.circuit = p.circuit;
                counts_arr[q.circuit] += 1;
                if (counts_arr[q.circuit] > max_count) {
                    max_count = counts_arr[q.circuit];
                    last_pair[0] = p;
                    last_pair[1] = q;
                }
            } else {
                counts_arr[p.circuit] += counts_arr[q.circuit];
                counts_arr[q.circuit] = 0;
                const qc = q.circuit;
                for (points[0..i]) |*x| {
                    if (x.circuit == qc) {
                        std.debug.print("Adding {d},{d},{d} to circuit {d}\n", .{ x.x, x.y, x.z, p.circuit });
                        x.circuit = p.circuit;
                    }
                }
                if (counts_arr[p.circuit] > max_count) {
                    max_count = counts_arr[p.circuit];
                    last_pair[0] = p;
                    last_pair[1] = q;
                }
            }
        }
        std.debug.print("Largest circuit contains: {d}\n", .{ max_count });
    }

    const answer = last_pair[0].x * last_pair[1].x;
    std.debug.print("Answer: {d}\n", .{ answer });
}

pub fn readPoint(input: *Reader) !Point {
    var num_str = try input.takeDelimiterInclusive(',');
    const x = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive(',');
    const y = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    num_str = try input.takeDelimiterInclusive('\n');
    const z = try std.fmt.parseInt(i64, num_str[0..num_str.len - 1], 10);

    return Point{ .x = x, .y = y, .z = z };
}

// returns the indexes of the two closest points
pub fn closest_pair(points: []Point, floor: *f32) ?[2]usize {
    var result: [2]usize = undefined;
    var min_dist: f32 = std.math.floatMax(f32);
    for (0..points.len) |p| {
        for (p + 1..points.len) |q| {
            const d = points[p].dist(points[q]);
            if (d > floor.* and d < min_dist) {
                result[0] = p;
                result[1] = q;
                min_dist = d;
            }
        }
    }
    if (min_dist < std.math.floatMax(f32)) {
        floor.* = min_dist;
        return result;
    }
    return null;
}
