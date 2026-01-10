# zig_life

Conway's Game of Life in Zig written in a weekend with dual build targets:
- Terminal - Native executable with ANSI rendering
- Web - WebAssembly + React with canvas rendering

## Requirements

- Zig 0.15.2
- Bun (for web frontend)

## Building and Running

### Terminal Version

```sh
zig build run
```

`Ctrl+C` to exit

### Web Version

```sh
# Build the WASM module
zig build wasm

# Install web deps and start dev server
cd web
bun install
bun dev
```

#### Controls

- `Space` to toggle running
- `s` to step
- `c` to clear
- Left mouse click to toggle cell
- Mouse drag support

## Architecture

```sh
src
├── core.zig      # Shared cgol logic
├── main.zig      # Entry point for terminal build target
├── terminal.zig  # ANSI terminal renderer + utils
└── wasm.zig      # WebAssembly exports
```

### Responsive Sizing

Both build targets support dynamic grid dimensions:

Terminal - On startup, the terminal size is queried via ioctl and calculates the maximum grid that fits within the available rows and columns.

Web - The React frontend measures the viewport and computes grid dimensions to fill the canvas. On window resize, the grid is re-initialized to match the new available space.

This means the simulation automatically scales to use your full screen real estate whether you're running in a small terminal pane or a maximized browser window.

### Zero-Copy Cell Access

The web frontend avoids copying cell data on every frame by reading directly from WASM linear memory. The `wasm.zig` module exposes:
```zig
export fn getCellsPtr() ?[*]core.Cell {
    return if (wasm_grid) |g| g.cells.ptr else null;
}

export fn getCellsLen() usize {
    return if (wasm_grid) |g| g.cells.len else 0;
}
```

On the TypeScript side, we create a Uint8Array view into the WASM memory buffer:
```typescript
export function getCellsArray(wasm: CGOLWasm): Uint8Array {
  const ptr = wasm.getCellsPtr();
  const len = wasm.getCellsLen();
  return new Uint8Array(wasm.memory.buffer, ptr, len);
}
```

This returns a live view; no data is copied. The renderer iterates over this array each frame to draw cells, achieving efficient O(1) access to the entire grid state without serialization overhead.

## License

SPDX-License-Identifier: MIT

Licensed under the MIT License. See [LICENSE](LICENSE) for full details.
