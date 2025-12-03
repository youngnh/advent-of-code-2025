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

    var infile_reader = infile.reader(try allocator.alloc(u8, 1024));
    var input = &infile_reader.interface;

    try input.fillMore();
    const buf = input.buffered();

    var i: usize = 0;
    var j: usize = 0;
    while (i < buf.len) {
        const start = i;
        while (buf[i] != '-') {
            i += 1;
        }
        const a = try std.fmt.parseInt(u64, buf[start..i], 10);
        std.debug.print("Found A: {d}\n", .{ a });

        i += 1; // advance past -
        j = i;
        while (buf[j] >= '0' and buf[j] <= '9') {
            j += 1;
        }
        const b = try std.fmt.parseInt(u64, buf[i..j], 10);
        std.debug.print("Found B: {d}\n\n", .{ b } );

        i = j + 1; // advance past ,
    }

    std.debug.print("Remaining: '{s}'\n", .{ buf[j..] });
}
