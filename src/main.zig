//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
const std = @import("std");
const rl = @import("raylib");
const Grid = @import("grid.zig");

pub fn main() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screen_width = 1200;
    const screen_height = 800;
    const cell_size = 5;
    const FPS = 12;
    const color_background = rl.Color.init(29, 29, 29, 255);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var title_buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&title_buffer);
    const title_allocator = fba.allocator();

    const grid = try Grid.init(allocator, screen_width, screen_height, cell_size);
    defer grid.deinit(allocator);
    grid.fill_random();

    rl.initWindow(screen_width, screen_height, "Game of Life");
    defer rl.closeWindow();

    rl.setTargetFPS(FPS);

    // Main game loop
    var iteration_count: usize = 0;
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Event Handling

        // Update State
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        grid.update();

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(color_background);

        grid.draw();

        //----------------------------------------------------------------------------------
        iteration_count += 1;
        const title = try std.fmt.allocPrintSentinel(title_allocator, "Game of Life ({d})", .{iteration_count}, 0);
        defer title_allocator.free(title);
        rl.setWindowTitle(title);
    }
}
