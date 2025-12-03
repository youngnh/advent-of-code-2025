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

    var answer: u64 = 0;
    while (input.peekByte()) |_| {
        const line = try input.takeDelimiterExclusive('\n');
        var batt = [12]u8 { '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1' };
        var batt_idx: usize = 0;

        var i: usize = 0;
        var lst_idx: usize = undefined;
        while (batt_idx < batt.len) {
            var end = line.len - batt.len + batt_idx + 1;
            if (batt_idx == 11) {
              end = line.len;
            }
            while (i < end) {
                if (line[i] > batt[batt_idx]) {
                    batt[batt_idx] = line[i];
                    lst_idx = i;
                }
                i += 1;
            }
            i = lst_idx + 1;
            batt_idx += 1;
        }

        const jolts = try std.fmt.parseInt(u64, batt[0..], 10);
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
