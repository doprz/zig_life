import { useCallback, useEffect, useRef, useState } from "react";
import { getCellsArray, type CGOLWasm } from "./wasm";

const CELL_SIZE = 10;
const DENSITY = 0.1;
const TICK_SPEED = 100; // in ms

interface Props {
  wasm: CGOLWasm;
}

export function GameOfLife({ wasm }: Props) {
  const [running, setRunning] = useState(false);
  const [initialized, setInitialized] = useState(false);

  const [_dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const [gridSize, setGridSize] = useState({ width: 0, height: 0 });

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animationRef = useRef<number>(0);
  const lastStepRef = useRef<number>(0);
  const [isDrawing, setIsDrawing] = useState(false);
  const lastCellRef = useRef<{ x: number; y: number } | null>(null);

  // Calculate grid size based on window size
  useEffect(() => {
    const updateDimensions = () => {
      const width = window.innerWidth;
      const height = window.innerHeight;
      const gridWidth = Math.floor(width / CELL_SIZE);
      const gridHeight = Math.floor(height / CELL_SIZE);

      setDimensions({ width, height });
      setGridSize({ width: gridWidth, height: gridHeight });

      console.log(
        `Window resized: ${width}x${height}, Grid size: ${gridWidth}x${gridHeight}`,
      );
    };

    updateDimensions();
    window.addEventListener("resize", updateDimensions);
    return () => window.removeEventListener("resize", updateDimensions);
  }, []);

  // Initialize WASM when grid size is known (or updated)
  useEffect(() => {
    if (gridSize.width > 0 && gridSize.height > 0) {
      const success = wasm.init(gridSize.width, gridSize.height);
      if (success) {
        wasm.randomize(BigInt(Date.now()), DENSITY);
        setInitialized(true);

        console.log(
          `Initialized with grid size ${gridSize.width}x${gridSize.height}`,
        );
      }
    }
  }, [wasm, gridSize]);

  const render = useCallback(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx || !initialized || gridSize.width === 0) return;

    const w = gridSize.width;
    const h = gridSize.height;
    const cells = getCellsArray(wasm);

    // Clear screen
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = "#d65d0e"; // Gruvbox orange
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        const idx = y * w + x;
        // Cell is alive
        if (cells[idx] === 1) {
          ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
        }
      }
    }
  }, [wasm, initialized, gridSize]);

  // Animation loop
  useEffect(() => {
    if (!initialized) return;

    const loop = (timestamp: number) => {
      if (running && timestamp - lastStepRef.current >= TICK_SPEED) {
        wasm.step();
        lastStepRef.current = timestamp;
      }
      render();
      animationRef.current = requestAnimationFrame(loop);
    };

    animationRef.current = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animationRef.current);
  }, [wasm, initialized, running, render]);

  // Keyboard controls
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      if (e.code === "Space") {
        e.preventDefault();
        setRunning((r) => !r);
      } else if (e.key === "s" || e.key === "S") {
        wasm.step();
        render();
      } else if (e.key === "c" || e.key === "C") {
        wasm.clear();
        render();
      }
    };

    window.addEventListener("keydown", handleKeyPress);
    return () => window.removeEventListener("keydown", handleKeyPress);
  }, [wasm, render]);

  const getCellCoords = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return null;

    const rect = canvas.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) / CELL_SIZE);
    const y = Math.floor((e.clientY - rect.top) / CELL_SIZE);

    if (x >= 0 && x < gridSize.width && y >= 0 && y < gridSize.height) {
      return { x, y };
    }
    return null;
  };

  const handleMouseDown = useCallback(
    (e: React.MouseEvent<HTMLCanvasElement>) => {
      setIsDrawing(true);
      const coords = getCellCoords(e);
      if (coords) {
        wasm.toggleCell(coords.x, coords.y);
        lastCellRef.current = coords;
      }
    },
    [wasm, render, gridSize],
  );

  const handleMouseMove = useCallback(
    (e: React.MouseEvent<HTMLCanvasElement>) => {
      if (!isDrawing) return;

      const coords = getCellCoords(e);
      if (
        coords &&
        (!lastCellRef.current ||
          coords.x !== lastCellRef.current.x ||
          coords.y !== lastCellRef.current.y)
      ) {
        wasm.toggleCell(coords.x, coords.y);
        lastCellRef.current = coords;
      }
    },
    [isDrawing, wasm, render, gridSize],
  );

  const handleMouseUp = useCallback(() => {
    setIsDrawing(false);
    lastCellRef.current = null;
  }, []);

  const handleMouseLeave = useCallback(() => {
    setIsDrawing(false);
    lastCellRef.current = null;
  }, []);

  return (
    <div className="bg-black flex w-screen h-screen overflow-hidden box-border m-0 p-0">
      <canvas
        ref={canvasRef}
        width={gridSize.width * CELL_SIZE}
        height={gridSize.height * CELL_SIZE}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseLeave}
        className="cursor-crosshair block"
      />
    </div>
  );
}
