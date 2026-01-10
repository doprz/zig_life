import { useEffect, useState } from "react";
import { loadWasm, type CGOLWasm } from "./wasm";
import { GameOfLife } from "./GameOfLife";

export default function App() {
  const [wasm, setWasm] = useState<CGOLWasm | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadWasm()
      .then(setWasm)
      .catch((e) => setError(e.message));
  }, []);

  if (error) {
    return (
      <div>
        <h2>Failed to load WASM</h2>
        <p>{error}</p>
      </div>
    );
  }

  if (!wasm) {
    return <div>Loading WASM module...</div>;
  }

  return <GameOfLife wasm={wasm} />;
}
