const std = @import("std");

pub const Config = struct {
    width: usize,
    height: usize,
};

pub const Cell = enum(u8) {
    dead = 0,
    alive = 1,

    pub fn toggle(self: Cell) Cell {
        return if (self == .alive) .dead else .alive;
    }
};

/// A 2D grid for Conway's Game of Life.
/// Stores cells in a flat array using row-major ordering.
pub const Grid = struct {
    cells: []Cell,
    width: usize,
    height: usize,
    generation: u64 = 0,

    const Self = @This();

    /// Creates a new grid with all cells initialized to dead.
    /// Returns an error if memory allocation fails.
    pub fn init(allocator: std.mem.Allocator, config: Config) !Self {
        const size = config.width * config.height;
        const cells = try allocator.alloc(Cell, size);
        @memset(cells, .dead);

        return .{
            .cells = cells,
            .width = config.width,
            .height = config.height,
        };
    }

    /// Frees the grid's memory and marks it as undefined.
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.cells);
        self.* = undefined;
    }

    /// Converts 2D coordinates to a 1D array index.
    pub fn index(self: *const Self, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    /// Returns the cell state at the given coordinates.
    /// Returns dead for out-of-bounds coordinates.
    pub fn get(self: *const Self, x: usize, y: usize) Cell {
        if (x >= self.width or y >= self.height) return .dead;
        return self.cells[self.index(x, y)];
    }

    /// Sets the cell state at the given coordinates.
    /// Does nothing if coordinates are out of bounds.
    pub fn set(self: *Self, x: usize, y: usize, cell: Cell) void {
        if (x >= self.width or y >= self.height) return;
        self.cells[self.index(x, y)] = cell;
    }

    /// Toggles the cell state at the given coordinates.
    /// Does nothing if coordinates are out of bounds.
    pub fn toggle(self: *Self, x: usize, y: usize) void {
        if (x >= self.width or y >= self.height) return;
        const idx = self.index(x, y);
        self.cells[idx] = self.cells[idx].toggle();
    }

    /// Clears the grid by setting all cells to dead and resetting generation to 0.
    pub fn clear(self: *Self) void {
        @memset(self.cells, .dead);
        self.generation = 0;
    }

    /// Counts the number of alive neighbors surrounding the given cell.
    /// Only considers the 8 adjacent cells (excludes diagonals outside bounds).
    pub fn countNeighbors(self: *Self, x: usize, y: usize) u8 {
        var count: u8 = 0;
        const offsets = [_]i8{ -1, 0, 1 };
        for (offsets) |dy| {
            for (offsets) |dx| {
                if (dx == 0 and dy == 0) continue;
                const nx = @as(isize, @intCast(x)) + dx;
                const ny = @as(isize, @intCast(y)) + dy;
                if (nx >= 0 and ny >= 0) {
                    if (self.get(@intCast(nx), @intCast(ny)) == .alive) {
                        count += 1;
                    }
                }
            }
        }

        return count;
    }

    /// Advances the simulation by one generation using Conway's Game of Life rules.
    /// Requires a scratch buffer the same size as the cell array.
    pub fn step(self: *Self, scratch: []Cell) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const neighbors = self.countNeighbors(x, y);
                const current = self.get(x, y);
                const idx = self.index(x, y);

                scratch[idx] = switch (current) {
                    .alive => if (neighbors == 2 or neighbors == 3) .alive else .dead,
                    .dead => if (neighbors == 3) .alive else .dead,
                };
            }
        }

        @memcpy(self.cells, scratch[0..self.cells.len]);
        self.generation += 1;
    }

    /// Returns the total number of alive cells in the grid.
    pub fn countAlive(self: *const Self) usize {
        var count: usize = 0;
        for (self.cells) |c| {
            if (c == .alive) count += 1;
        }

        return count;
    }

    /// Adds a pattern to the grid at the specified offset position.
    /// Only places cells that fall within the grid boundaries.
    fn addPattern(self: *Self, ox: usize, oy: usize, pattern: []const [2]usize) void {
        for (pattern) |pos| {
            const px = ox +| pos[0];
            const py = oy +| pos[1];
            if (px < self.width and py < self.height) {
                self.set(px, py, .alive);
            }
        }
    }

    /// Fills the grid with randomly placed alive cells based on the given density.
    /// Resets the generation counter to 0.
    pub fn randomize(self: *Self, seed: u64, density: f32) void {
        var prng = std.Random.DefaultPrng.init(seed);
        const random = prng.random();

        for (self.cells) |*cell| {
            cell.* = if (random.float(f32) < density) .alive else .dead;
        }
        self.generation = 0;
    }

    /// Adds a glider pattern at the specified position.
    /// A glider is a small spaceship that moves diagonally across the grid.
    pub fn addGlider(self: *Self, x: usize, y: usize) void {
        const pattern = [_][2]usize{
            .{ 1, 0 }, .{ 2, 1 }, .{ 0, 2 }, .{ 1, 2 }, .{ 2, 2 },
        };
        self.addPattern(x, y, &pattern);
    }
};
