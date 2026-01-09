const std = @import("std");
const core = @import("core.zig");
const terminal = @import("terminal.zig");

const Config = struct {
    width: usize = 60,
    height: usize = 40,
    tick_ms: u64 = 100, // in ms
    initial_density: f16 = 0.1,
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var config = Config{};

    if (terminal.getTermSize(std.fs.File.stdout())) |term_size| {
        // Render 2 term chars per game cell for square pixels
        config.width = term_size.width / 2;
        config.height = term_size.height & ~@as(u16, 1); // Round down to closest even num
        std.debug.print("Using terminal size: {}x{}\n", .{ term_size.width, term_size.height });
    } else |err| {
        std.debug.print("Could not get terminal size ({s}), using defaults: {}x{}\n", .{
            @errorName(err),
            config.width,
            config.height,
        });
    }

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

    const buffer_size = config.width * config.height;
    const stdout_buffer = try allocator.alloc(u8, buffer_size);
    defer allocator.free(stdout_buffer);

    var stdout_writer = std.fs.File.stdout().writer(stdout_buffer);
    const stdout = &stdout_writer.interface;

    // std.Thread.sleep(1000 * std.time.ns_per_ms);
    // std.debug.print("Config: {}", .{config});

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
