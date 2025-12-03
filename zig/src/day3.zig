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

    var infile_reader = infile.reader(try allocator.alloc(u8, 1024));
    var input = &infile_reader.interface;

    var answer: u32 = 0;
    while (input.peekByte()) |_| {
        const line = try input.takeDelimiterExclusive('\n');

        var i: usize = 0;
        var fst: u8 = '1';
        var fst_idx: usize = undefined;
        while (i < line.len - 1) {
            if (line[i] > fst) {
                fst = line[i];
                fst_idx = i;
            }
            i += 1;
        }

        i = fst_idx + 1;
        var snd: u8 = line[i];
        while (i < line.len) {
            if (line[i] > snd) {
                snd = line[i];
            }
            i += 1;
        }

        const digits = [_]u8{ fst, snd };
        const jolts = try std.fmt.parseInt(u32, digits[0..], 10);
        std.debug.print("Jolts: {d}\n", .{ jolts });
        answer += jolts;

        _ = try input.takeByte();
    } else |_| {
        // reached end of input
    }

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer: {d}\n", .{ answer });
    try stdout.flush();
}
