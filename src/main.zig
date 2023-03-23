const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub fn Graph(comptime T: type) type {
    return CSRGraph(T);
}

/// Graph stored as adjacency matrix in compressed sparse row format
fn CSRGraph(comptime T: type) type {
    return struct {
        const Self = @This();

        size: u64,
        values: std.ArrayList(T),
        column_indices: std.ArrayList(u64),
        row_indices: std.ArrayList(u64),

        pub fn init(allocator: Allocator) Allocator.Error!Self {
            var self = Self {
                .size = 0,
                .values = std.ArrayList(T).init(allocator),
                .column_indices = std.ArrayList(u64).init(allocator),
                .row_indices = try std.ArrayList(u64).initCapacity(allocator, 1),
            };
            self.row_indices.appendAssumeCapacity(0);
            return self;
        }

        pub fn deinit(self: *Self) void {
            self.values.deinit();
            self.column_indices.deinit();
            self.row_indices.deinit();
        }

        pub fn dump_debug(self: *Self) void {
            std.debug.print("-- Graph: --\nn = {d}\nc = [ ", .{ self.size });
            for (self.column_indices.items) |c| {
                std.debug.print("{d} ", .{ c });
            }
            std.debug.print("]\nr = [ ", .{});
            for (self.row_indices.items) |r| {
                std.debug.print("{d} ", .{ r });
            }
            std.debug.print("]\n", .{});
            for (0..self.size) |row| {
                std.debug.print("[ ", .{});

                var row_start = self.row_indices.items[row];
                var row_end = self.row_indices.items[row + 1];
                var col_i: u64 = row_start;
                for (0..self.size) |col| {
                    if (col_i < row_end and col == self.column_indices.items[col_i]) {
                        std.debug.print("1 ", .{});
                        col_i += 1;
                    } else {
                        std.debug.print("0 ", .{});
                    }
                }

                std.debug.print("]\n", .{});
            }
        }

        pub fn add_vertex(self: *Self, value: T) Allocator.Error!u64 {
            var index = self.size;
            self.size += 1;

            try self.values.append(value);

            // Add empty row
            var non_zero_entries = self.row_indices.getLast();
            try self.row_indices.append(non_zero_entries);

            return index;
        }

        pub fn add_edge(self: *Self, from: u64, to: u64) Allocator.Error!void {
            std.debug.assert(from < self.size and to < self.size);

            // Insert column index
            var row_start = self.row_indices.items[from];
            var row_end = self.row_indices.items[from + 1];
            var insert_offset: u32 = 0;
            for (self.column_indices.items[row_start..row_end], row_start..row_end) |col, offset| {
                std.debug.print("offset {d} col {d}", .{ offset, col });
            }
            try self.column_indices.insert(row_start + insert_offset, to);

            // Update row indices
            for ((from + 1)..(self.size + 1)) |i| {
                self.row_indices.items[i] += 1;
            }
        }
    };
}

test "CSRGraph" {
    std.debug.print("\n", .{});

    var g = try CSRGraph(i32).init(testing.allocator);
    defer g.deinit();

    g.dump_debug();
    var a = try g.add_vertex(15);
    g.dump_debug();
    var b = try g.add_vertex(23);
    g.dump_debug();
    var c = try g.add_vertex(50);

    g.dump_debug();
    try g.add_edge(a, b);

    g.dump_debug();
    try g.add_edge(b, c);

    g.dump_debug();
}
