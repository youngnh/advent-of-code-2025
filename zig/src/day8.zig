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

    pub fn dist_d(self: Point, other: Point, dim: u8) f32 {
        const dx = other.x - self.x;
        const x2 = dx * dx;
        const dy = other.y - self.y;
        const y2 = dy * dy;
        const dz = other.z - self.z;
        const z2 = dz * dz;

        switch (dim) {
            1 => {
                const result: f32 = @floatFromInt(dx);
                return result;
            },
            2 => {
                const sum: f32 = @floatFromInt(x2 + y2);
                return std.math.sqrt(sum);
            },
            else => {
                const sum: f32 = @floatFromInt(x2 + y2 + z2);
                return std.math.sqrt(sum);
            },
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const argv = try std.process.argsAlloc(allocator);

    if (argv.len < 3) {
        std.process.fatal("Expected input and num_circuits argument, but none given\n", .{});
    }

    const infile = try std.fs.cwd().openFile(argv[1], .{ .mode = .read_only });
    defer infile.close();

    var infile_reader = infile.reader(try allocator.alloc(u8, 20 * 1024));
    const input = &infile_reader.interface;

    const num_circuits: u32 = try std.fmt.parseInt(u32, argv[2], 10);

    var i: usize = 0;
    var points: [1024]Point = undefined;
    while (input.peekByte()) |_| {
        points[i] = try readPoint(input);
        i += 1;
    } else |_| {
        // end of input
    }
    std.debug.print("Read {d} points\n", .{ i });

    var next_circuit: u32 = 1;
    var counts_arr = [_]u32{0} ** 1024;
    var min_dist: f32 = undefined;
    for (0..num_circuits) |n| {
        if(closest_pair(points[0..i], &min_dist)) |idxs| {
            var p = &points[idxs[0]];
            var q = &points[idxs[1]];
            const d = p.dist(q.*);
            std.debug.print("{d}: Closest points: {d},{d},{d} and {d},{d},{d} at dist {d}\n", .{ n, p.x, p.y, p.z, q.x, q.y, q.z, d });

            if (p.circuit == 0 and q.circuit == 0) {
                std.debug.print("Placing {d},{d},{d} and {d},{d},{d} on their own circuit {d}\n", .{ p.x, p.y, p.z, q.x, q.y, q.z, next_circuit });
                p.circuit = next_circuit;
                q.circuit = next_circuit;
                counts_arr[next_circuit] += 2;
                next_circuit += 1;
            } else if (p.circuit == q.circuit) {
                std.debug.print("Both already connected\n", .{});
            } else if (q.circuit == 0) {
                std.debug.print("Adding {d},{d},{d} to circuit {d}\n", .{ q.x, q.y, q.z, p.circuit });
                q.circuit = p.circuit;
                counts_arr[q.circuit] += 1;
            } else if (p.circuit == 0) {
                std.debug.print("Adding {d},{d},{d} to circuit {d}\n", .{ p.x, p.y, p.z, q.circuit });
                p.circuit = q.circuit;
                counts_arr[p.circuit] += 1;
            } else {
                // add all boxes in q's circuit to p's circuit
                std.debug.print("Combining circuit {d} with circuit {d}\n", .{ p.circuit, q.circuit });
                counts_arr[p.circuit] += counts_arr[q.circuit];
                counts_arr[q.circuit] = 0;
                for (points[0..i]) |*x| {
                    if (x.circuit == q.circuit) {
                        std.debug.print("Adding {d},{d},{d} to circuit {d}\n", .{ x.x, x.y, x.z, p.circuit });
                        x.circuit = p.circuit;
                    }
                }
            }

            std.debug.print("\n", .{});
        }
    }

    const counts = counts_arr[1..next_circuit];
    std.mem.sort(u32, counts, {}, std.sort.desc(u32));
    for(counts) |c| {
        std.debug.print("{d} ", .{ c });
    }
    std.debug.print("\n", .{});

    var answer: u32 = 1;
    for (counts[0..3]) |c| {
        answer *= c;
    }
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
