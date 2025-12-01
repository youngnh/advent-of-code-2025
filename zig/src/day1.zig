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
    var dial: i32 = 50;
    while(input.interface.takeByte()) |ch| {
        if (try input.interface.takeDelimiter('\n')) |str| {
            const n = try std.fmt.parseInt(i32, str, 10);
            if (ch == 'R') {
                dial += n;
            } else if (ch == 'L') {
                dial -= n;
            } else {
                std.process.fatal("Invalid rotation instruction {c}\n", .{ ch });
            }
            dial = @mod(dial, 100);
            std.debug.print("Rotated to point at {d}\n", .{ dial });
            if (dial == 0) {
                answer += 1;
            }
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
