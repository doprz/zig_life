export interface CGOLWasm {
  memory: WebAssembly.Memory;

  // Match exports in src/wasm.zig
  init(width: number, height: number): boolean;
  getCellsPtr(): number;
  getCellsLen(): number;

  step(): void;
  clear(): void;
  randomize(seed: bigint, density: number): void;

  getCell(x: number, y: number): number;
  setCell(x: number, y: number, alive: number): void;
  toggleCell(x: number, y: number): void;
}

let wasmInstance: CGOLWasm | null = null;

export async function loadWasm(): Promise<CGOLWasm> {
  if (wasmInstance) return wasmInstance;

  const response = await fetch("/zig_life_wasm.wasm");
  const bytes = await response.arrayBuffer();

  const { instance } = await WebAssembly.instantiate(bytes, {});

  wasmInstance = instance.exports as unknown as CGOLWasm;
  return wasmInstance;
}

export function getCellsArray(wasm: CGOLWasm): Uint8Array {
  const ptr = wasm.getCellsPtr();
  const len = wasm.getCellsLen();
  return new Uint8Array(wasm.memory.buffer, ptr, len);
}
