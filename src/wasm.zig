const std = @import("std");
const core = @import("core.zig");

const allocator = std.heap.page_allocator;

var wasm_grid: ?core.Grid = null;
var wasm_scratch: ?[]core.Cell = null;

export fn init(width: u32, height: u32) bool {
    wasm_grid = core.Grid.init(allocator, .{
        .width = width,
        .height = height,
    }) catch return false;

    const size = width * height;
    wasm_scratch = allocator.alloc(core.Cell, size) catch return false;
    // FIX: Make sure to free memory ouside of init

    return true;
}

export fn getCellsPtr() ?[*]core.Cell {
    return if (wasm_grid) |g| g.cells.ptr else null;
}

export fn getCellsLen() usize {
    return if (wasm_grid) |g| g.cells.len else 0;
}

export fn step() void {
    if (wasm_grid) |*g| {
        if (wasm_scratch) |s| g.step(s);
    }
}

export fn clear() void {
    if (wasm_grid) |*g| g.clear();
}

export fn randomize(seed: u64, density: f32) void {
    if (wasm_grid) |*g| g.randomize(seed, density);
}

export fn getCell(x: u32, y: u32) u8 {
    return if (wasm_grid) |g| @intFromEnum(g.get(x, y)) else 0;
}

export fn setCell(x: u32, y: u32, alive: u8) void {
    if (wasm_grid) |*g| {
        g.set(x, y, if (alive != 0) .alive else .dead);
    }
}

export fn toggleCell(x: u32, y: u32) void {
    if (wasm_grid) |*g| g.toggle(x, y);
}
