// file is structure
//

const std = @import("std");
const Allocator = std.mem.Allocator;
const rl = @import("raylib");

rows: u32,
columns: u32,
cell_size: u32,
cells: [][]usize,
next_cells: [][]usize,
allocator: Allocator,

const Self = @This();

pub fn init(allocator: Allocator, width: i32, height: i32, size: u32) !Self {
    const rows = @as(u32, @intCast(width)) / size;
    const columns = @as(u32, @intCast(height)) / size;
    const cells = try allocator.alloc([]usize, rows);
    for (0..rows) |row| {
        cells[row] = try allocator.alloc(usize, columns);
        @memset(cells[row], 0);
    }
    std.log.info("rows = {} columns = {}\n", .{ rows, columns });
    const next_cells = try allocator.alloc([]usize, rows);
    for (0..rows) |row| {
        next_cells[row] = try allocator.alloc(usize, columns);
    }
    return .{
        .allocator = allocator,
        .rows = rows,
        .columns = columns,
        .cell_size = size,
        .cells = cells,
        .next_cells = next_cells,
    };
}

pub fn deinit(self: Self) void {
    for (0..self.columns) |col| {
        self.allocator.free(self.cells[col]);
        self.allocator.free(self.next_cells[col]);
    }
    self.allocator.free(self.cells);
    self.allocator.free(self.next_cells);
}

pub fn fill_random(self: Self) void {
    for (0..self.rows) |row| {
        for (0..self.columns) |col| {
            self.cells[row][col] = if (rl.getRandomValue(0, 3) == 0) 1 else 0;
        }
    }
}

pub fn draw(self: Self) void {
    for (0..self.rows) |row| {
        for (0..self.columns) |col| {
            const y: i32 = @intCast(col * self.cell_size);
            const x: i32 = @intCast(row * self.cell_size);
            const size: i32 = @intCast(self.cell_size);
            var color = rl.Color.gray;
            const value = self.cells[row][col];
            if (value > 0 and value < 256) {
                color = rl.Color.init(255, 0, 0, @intCast(value % 255));
            } else if (value >= 256 and value < 512) {
                color = rl.Color.init(0, 255, 0, @intCast(value % 255));
            } else if (value >= 512 and value < 768) {
                color = rl.Color.init(0, 0, 255, @intCast(value % 255));
            } else if (value >= 768) {
                color = rl.Color.white;
            }
            rl.drawRectangle(x, y, size - 1, size - 1, color);
        }
    }
}

pub fn isWithinBounds(self: Self, row: usize, column: usize) bool {
    if (row >= 0 and row < self.rows and column >= 0 and column <= self.columns) {
        return true;
    }
    return false;
}

pub fn setValue(self: Self, row: usize, column: usize, value: usize) void {
    if (self.isWithinBounds(row, column)) {
        self.cells[row][column] = value;
    }
}

pub fn getValue(self: Self, row: usize, column: usize) usize {
    if (self.isWithinBounds(row, column)) {
        return self.cells[row][column];
    }
    return 0;
}

const Offset = struct { x: i32, y: i32 };
const neighbor_offsets = [_]Offset{
    Offset{ .x = -1, .y = 0 },
    Offset{ .x = 1, .y = 0 },
    Offset{ .x = 0, .y = -1 },
    Offset{ .x = 0, .y = 1 },
    Offset{ .x = -1, .y = -1 },
    Offset{ .x = -1, .y = 1 },
    Offset{ .x = 1, .y = -1 },
    Offset{ .x = 1, .y = 1 },
};

pub fn countLiveNeighbors(self: Self, row: usize, column: usize) u32 {
    var live_neighbors: u32 = 0;
    for (neighbor_offsets) |offset| {
        const r1 = @as(i32, @intCast(row + self.rows)) + offset.x;
        const c1 = @as(i32, @intCast(column + self.columns)) + offset.y;
        const neighbor_row = @as(u32, @intCast(r1)) % self.rows;
        const neighbor_column = @as(u32, @intCast(c1)) % self.columns;
        if (self.getValue(neighbor_row, neighbor_column) > 0) {
            live_neighbors += 1;
        }
    }

    return live_neighbors;
}

pub fn update(self: Self) void {
    for (0..self.rows) |row| {
        for (0..self.columns) |col| {
            const live_neighbors = self.countLiveNeighbors(row, col);
            var cell_value = self.cells[row][col];
            if (cell_value > 0) {
                if (live_neighbors > 3 or live_neighbors < 2) {
                    self.next_cells[row][col] = 0;
                } else {
                    cell_value += 1;
                    self.next_cells[row][col] = cell_value;
                }
            } else {
                self.next_cells[row][col] = if (live_neighbors == 3) 1 else 0;
            }
        }
    }
    for (0..self.rows) |row| {
        for (0..self.columns) |col| {
            self.cells[row][col] = self.next_cells[row][col];
        }
    }
}
