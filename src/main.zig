const std = @import("std");
const core = @import("core.zig");
const terminal = @import("terminal.zig");

const Config = struct {
    width: usize = 60,
    height: usize = 40,
    tick_ms: u64 = 100, // in ms
    initial_density: f32 = 0.5,
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const config = Config{};

    var grid = try core.Grid.init(allocator, .{
        .width = config.width,
        .height = config.height,
    });
    defer grid.deinit(allocator);

    const scratch = try allocator.alloc(core.Cell, config.width * config.height);
    defer allocator.free(scratch);

    const seed: u64 = @intCast(std.time.timestamp());
    grid.randomize(seed, config.initial_density);
    grid.addGlider(5, 5);

    const buffer_size = (config.width * config.height * 20);
    var stdout_buffer: [buffer_size]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var term = terminal.Terminal.init(stdout);
    try term.hideCursor();
    try term.clear();
    defer term.showCursor() catch {};

    while (true) {
        try term.render(&grid);
        try stdout.flush();
        grid.step(scratch);
        std.Thread.sleep(config.tick_ms * std.time.ns_per_ms);
    }
}
