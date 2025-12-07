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

    var beams = try allocator.alloc(u8, startLine.len - 1);
    beams[start_idx] = 1;

    var answer: u32 = 0;
    while (input.peekByte()) |_| {
        const line = try input.takeDelimiterInclusive('\n');
        var c: usize = 0;
        while (c < beams.len) {
            if (line[c] == '^' and beams[c] == 1) {
                if (c >= 1) {
                    beams[c - 1] = 1;
                }
                beams[c] = 0;
                if (c + 1 < beams.len) {
                    beams[c + 1] = 1;
                }
                answer += 1;
            }
            c += 1;
        }
    } else |_| {
        // end of input
    }

    std.debug.print("Answer: {d}\n", .{ answer });
}
