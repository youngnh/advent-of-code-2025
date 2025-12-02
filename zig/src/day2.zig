const std = @import("std");

pub fn invalid_id(str: []const u8) bool {
    if (str.len % 2 == 1) {
        return false;
    }
    var i: usize = 0;
    var j: usize = str.len / 2;
    while (j < str.len) {
        if (str[i] != str[j]) {
            return false;
        }
        i += 1;
        j += 1;
    }
    return true;
}

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
    var infile_reader = infile.reader(buf);
    var input = &infile_reader.interface;

    var answer: u64 = 0;
    const print_buf = try allocator.alloc(u8, 1024);

    while (input.takeDelimiter('-')) |num_str_opt| {
        if (num_str_opt) |num_str_a| {
            std.debug.print("Parsing a: {s}\n", .{ num_str_a });
            var a = try std.fmt.parseInt(u64, num_str_a, 10);

            if (input.takeDelimiter(',')) |num_str_opt2| {
                if (num_str_opt2) |num_str_b| {
                    var b: u64 = undefined;
                    const end = num_str_b.len - 1;
                    if (num_str_b[end] == '\n') {
                        std.debug.print("Trailing newline\n", .{});
                        std.debug.print("Parsing b: {s}$\n", .{ num_str_b[0..end] });
                        b = try std.fmt.parseInt(u64, num_str_b[0..end], 10);
                    } else {
                        std.debug.print("Parsing b: {s}$\n", .{ num_str_b });
                        b = try std.fmt.parseInt(u64, num_str_b, 10);
                    }

                    while (a <= b) {
                        std.debug.print("Testing: {d}\n", .{ a });
                        const idstr = try std.fmt.bufPrint(print_buf, "{d}", .{ a });
                        if (invalid_id(idstr)) {
                            answer += a;
                        }
                        a += 1;
                    }
                }
            } else |_| {
                // end of input
            }
            std.debug.print("Next iteration of loop {d}\n", .{ answer });
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
