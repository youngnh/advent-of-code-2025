const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;

const Range = struct {
    start: u64,
    end: u64,
    node: DoublyLinkedList.Node,
};

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

    var database: DoublyLinkedList = .{};
    var rangeNodes: [256]Range = undefined;
    var i: usize = 0;
    var num_str: []u8 = undefined;
    while (try input.peekByte() != '\n') {
        // read start of range
        num_str = try input.takeDelimiterExclusive('-');
        const lo = try std.fmt.parseInt(u64, num_str, 10);
        input.toss(1);

        // read end of range
        num_str = try input.takeDelimiterExclusive('\n');
        const hi = try std.fmt.parseInt(u64, num_str, 10);
        input.toss(1);

        if (database.first) |n| {
            var rng: *Range = @fieldParentPtr("node", n);
            while (lo > rng.start) {
                if (rng.node.next) |rn| {
                    rng = @fieldParentPtr("node", rn);
                } else {
                    break;
                }
            }
            rangeNodes[i] = .{ .start = lo, .end = hi, .node = .{} };
            if (lo < rng.start) {
                database.insertBefore(&rng.node, &rangeNodes[i].node);
            } else {
                database.insertAfter(&rng.node, &rangeNodes[i].node);
            }
            i += 1;
        } else {
            rangeNodes[i] = .{ .start = lo, .end = hi, .node = .{} };
            database.prepend(&rangeNodes[i].node);
            i += 1;
        }
    }

    var answer: u64 = 0;
    var last: u64 = 0;
    var range = database.first;
    while (range) |r| {
        const rng: *Range = @fieldParentPtr("node", r);
        var extra: u64 = 1;
        var lo = rng.start;
        if (last >= rng.start) {
            lo = last;
            extra = 0;
        }
        if (rng.end >= lo) {
            std.debug.print("Range {d}-{d}, {d}-{d} {d}\n", .{ rng.start, rng.end, lo, rng.end, extra });
            answer += (rng.end - lo + extra);
            last = rng.end;
        } else {
            std.debug.print("Range {d}-{d}\n", .{ rng.start, rng.end });
        }
        range = r.next;
    }

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;

    try stdout.print("Answer: {d}\n", .{ answer });
    try stdout.flush();
}
