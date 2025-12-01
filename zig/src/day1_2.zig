const std = @import("std");

pub fn main () !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const argv = try std.process.argsAlloc(allocator);

    if (argv.len < 2) {
      std.process.fatal("Expected input argument, but none given", .{});
    }

    const infile = try std.fs.cwd().openFile(argv[1], .{ .mode = .read_only });
    defer infile.close();

    const buf = try allocator.alloc(u8, 1024);
    
    var input = infile.reader(buf);

    var answer: u32 = 0;
    var dial: u32 = 50;
    while(input.interface.takeByte()) |ch| {
        if (try input.interface.takeDelimiter('\n')) |str| {
            var n = try std.fmt.parseInt(u32, str, 10);
            answer += n / 100;
            n %= 100;
            if (ch == 'R') {
                dial += n;
                if (dial > 99) {
                    answer += 1;
                    dial %= 100;
                }
            } else if (ch == 'L') {
                if (dial == 0) {
                    dial = 100 - n;
                } else if (n > dial) {
                    answer += 1;
                    dial = 100 - (n - dial);
                } else {
                    dial -= n;
                }

                if (dial == 0) {
                    answer += 1;
                }
            } else {
                std.process.fatal("Invalid rotation instruction {c}\n", .{ ch });
            }
            std.debug.print("Rotate {c} by {d}, dial points at {d}, zeros: {d}\n", .{ ch, n, dial, answer });
        }
    } else |_| {
        // reached end of input
    }

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer: {d}\n", .{ answer });
    try stdout.flush();
}
