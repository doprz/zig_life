const std = @import("std");
const builtin = @import("builtin");
const core = @import("core.zig");

/// Terminal size measured in chars
pub const TermSize = struct {
    width: u16,
    height: u16,
};

pub const TermSizeError = error{
    Unsupported,
    TerminalSizeUnavailable,
};

/// Retrieves the terminal window size.
/// Currently only supported on Linux systems with ANSI escape code support.
pub fn getTermSize(file: std.fs.File) TermSizeError!TermSize {
    if (!file.supportsAnsiEscapeCodes()) {
        return TermSizeError.Unsupported;
    }

    return switch (builtin.os.tag) {
        .linux => {
            var ws: std.posix.winsize = undefined;
            const result = std.os.linux.ioctl(file.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&ws));

            if (result != 0) return TermSizeError.TerminalSizeUnavailable;
            return .{
                .width = ws.col,
                .height = ws.row,
            };
        },
        else => TermSizeError.Unsupported,
    };
}

/// Terminal control operations using ANSI escape codes.
pub const Terminal = struct {
    writer: *std.Io.Writer,

    const Self = @This();
    const ESC = "\x1b";

    pub fn init(writer: *std.Io.Writer) Self {
        return .{ .writer = writer };
    }

    pub fn clear(self: *Self) !void {
        try self.writer.writeAll(ESC ++ "[2J" ++ ESC ++ "[H");
    }

    pub fn hideCursor(self: *Self) !void {
        try self.writer.writeAll(ESC ++ "[?25l");
    }

    pub fn showCursor(self: *Self) !void {
        try self.writer.writeAll(ESC ++ "[?25h");
    }

    pub fn moveTo(self: *Self, x: usize, y: usize) !void {
        try self.writer.print(ESC ++ "[{d};{d}H", .{ y + 1, x + 1 });
    }

    pub fn setColor(self: *Self, fg: u8, bg: u8) !void {
        try self.writer.print(ESC ++ "[0;{d};{d}m", .{ fg, bg });
    }

    pub fn resetColor(self: *Self) !void {
        try self.writer.writeAll(ESC ++ "[0m");
    }

    pub fn render(self: *Self, grid: *const core.Grid) !void {
        try self.moveTo(0, 0);

        for (0..grid.height) |y| {
            for (0..grid.width) |x| {
                const cell = grid.get(x, y);
                if (cell == .alive) {
                    try self.setColor(37, 49); // White
                    try self.writer.writeAll("██");
                } else {
                    try self.setColor(39, 0); // Default
                    try self.writer.writeAll("  ");
                }
            }
            try self.writer.writeAll("\n");
        }
    }
};
