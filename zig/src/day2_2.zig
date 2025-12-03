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
        const numstr_a = buf[start..i];
        std.debug.print("Found A: '{s}'\n", .{ numstr_a });

        i += 1; // advance past -
        j = i;
        while (buf[j] >= '0' and buf[j] <= '9') {
            j += 1;
        }
        const numstr_b = buf[i..j];
        std.debug.print("Found B: '{s}'\n\n", .{ numstr_b} );

        i = j + 1; // advance past ,
    }

    std.debug.print("Remaining: '{s}'\n", .{ buf[j..] });
}
