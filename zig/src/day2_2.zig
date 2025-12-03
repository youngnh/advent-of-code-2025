const std = @import("std");

pub fn check_repeat(str: []const u8, r: usize) bool {
    // std.debug.print("Check if {s} has {d} repetitions of a {d} length pattern\n", .{ str, n, r });
    var i: usize = 0;
    var j: usize = r;
    while (j < str.len) {
        if (str[i] != str[j]) {
            return false;
        }
        i += 1;
        i %= r;
        j += 1;
    }
    return true;
}

pub fn invalid_id(str: []const u8) bool {
    var r: usize = 1;
    while (r < str.len) {
        if (str.len % r == 0) {
            const invalid = check_repeat(str, r);
            if (invalid) {
                std.debug.print("String {s} has {d} repetitions of {d} length patterns\n", .{ str, str.len / r, r });
                return invalid;
            }
        }
        r += 1;
    }
    return false;
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

    var infile_reader = infile.reader(try allocator.alloc(u8, 1024));
    var input = &infile_reader.interface;

    try input.fillMore();
    const buf = input.buffered();

    var i: usize = 0;
    var j: usize = 0;
    var answer: u64 = 0;
    const print_buf = try allocator.alloc(u8, 1024);

    while (i < buf.len) {
        const start = i;
        while (buf[i] != '-') {
            i += 1;
        }
        var a = try std.fmt.parseInt(u64, buf[start..i], 10);
        std.debug.print("Found A: {d}\n", .{ a });

        i += 1; // advance past -
        j = i;
        while (buf[j] >= '0' and buf[j] <= '9') {
            j += 1;
        }
        const b = try std.fmt.parseInt(u64, buf[i..j], 10);
        std.debug.print("Found B: {d}\n\n", .{ b } );

        while (a <= b) {
            const idstr = try std.fmt.bufPrint(print_buf, "{d}", .{ a });
            if (invalid_id(idstr)) {
                answer += a;
            }
            a += 1;
        }

        // next iteration
        i = j + 1; // advance past ,
    }


    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer: {d}\n", .{ answer });
    try stdout.flush();
}
