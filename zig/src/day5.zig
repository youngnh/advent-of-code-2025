const std = @import("std");

const Range = struct {
    start: u64,
    end: u64,
};

pub fn search_for(n: u64, database: []Range) bool {
    for (database) |range| {
        if (n >= range.start and n <= range.end) {
            return true;
        }
    }
    return false;
}

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

    var infile_reader = infile.reader(try allocator.alloc(u8, 1024));
    var input = &infile_reader.interface;

    var database_buf: [256]Range = undefined;
    var num_str: []u8 = undefined;
    var i: u32 = 0;

    while (try input.peekByte() != '\n') {
        // read start of range
        num_str = try input.takeDelimiterExclusive('-');
        database_buf[i].start = try std.fmt.parseInt(u64, num_str, 10);
        input.toss(1);

        // read end of range
        num_str = try input.takeDelimiterExclusive('\n');
        database_buf[i].end = try std.fmt.parseInt(u64, num_str, 10);
        input.toss(1);

        i += 1;
    }
    input.toss(1);
    const database = database_buf[0..i];
    std.debug.print("Read {d} ingredient ranges\n", .{ database.len });

    var answer: u32 = 0;
    while (input.peek(1)) |_| {
        num_str = try input.takeDelimiterExclusive('\n');
        const n = try std.fmt.parseInt(u64, num_str, 10);
        input.toss(1);

        if (search_for(n, database)) {
            answer += 1;
        }
    } else |_| {
        // end of input
    }


    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer: {d}\n", .{ answer });
    try stdout.flush();
}
