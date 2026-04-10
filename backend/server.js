// ─────────────────────────────────────────────────────────────────────────
// UrbanPath — Node.js API Gateway
// Bridges the web frontend ↔ C++ pathfinder engine ↔ Supabase database
// ─────────────────────────────────────────────────────────────────────────

import express from "express";
import cors from "cors";
import { spawn } from "child_process";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

dotenv.config();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "../frontend")));

// ── Supabase Client ───────────────────────────
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ─────────────────────────────────────────────
// Helper: Run C++ pathfinder with JSON I/O
// ─────────────────────────────────────────────
function runPathfinder(payload) {
  return new Promise((resolve, reject) => {
    const cppBinary = path.join(__dirname, "../cpp/pathfinder");
    const proc = spawn(cppBinary, [], { stdio: ["pipe", "pipe", "pipe"] });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (d) => (stdout += d));
    proc.stderr.on("data", (d) => (stderr += d));

    proc.on("close", (code) => {
      if (code !== 0) return reject(new Error(`C++ exited ${code}: ${stderr}`));
      try {
        resolve(JSON.parse(stdout));
      } catch (e) {
        reject(new Error(`JSON parse failed: ${stdout}`));
      }
    });

    proc.stdin.write(JSON.stringify(payload));
    proc.stdin.end();
  });
}

// ─────────────────────────────────────────────
// GET /api/maps — list available city maps
// ─────────────────────────────────────────────
app.get("/api/maps", async (req, res) => {
  const { data, error } = await supabase.from("maps").select("*").order("name");
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// ─────────────────────────────────────────────
// GET /api/maps/:mapId/graph — load nodes + edges
// ─────────────────────────────────────────────
app.get("/api/maps/:mapId/graph", async (req, res) => {
  const { mapId } = req.params;

  const [nodesRes, edgesRes] = await Promise.all([
    supabase.from("nodes").select("*").eq("map_id", mapId),
    supabase.from("edges").select("*").eq("map_id", mapId),
  ]);

  if (nodesRes.error) return res.status(500).json({ error: nodesRes.error.message });
  if (edgesRes.error) return res.status(500).json({ error: edgesRes.error.message });

  res.json({ nodes: nodesRes.data, edges: edgesRes.data });
});

// ─────────────────────────────────────────────
// POST /api/route — run pathfinding algorithms
// Body: { map_id, source, target, algorithm }
// ─────────────────────────────────────────────
app.post("/api/route", async (req, res) => {
  const { map_id, source, target, algorithm = "both" } = req.body;

  if (!map_id || source == null || target == null) {
    return res.status(400).json({ error: "map_id, source, and target are required." });
  }

  try {
    // Fetch graph from DB
    const [nodesRes, edgesRes] = await Promise.all([
      supabase.from("nodes").select("id, lat, lng, name").eq("map_id", map_id),
      supabase.from("edges").select("from_node as from, to_node as to, weight, bidirectional").eq("map_id", map_id),
    ]);

    if (nodesRes.error) throw new Error(nodesRes.error.message);
    if (edgesRes.error) throw new Error(edgesRes.error.message);

    // Forward to C++ engine
    const payload = {
      nodes: nodesRes.data,
      edges: edgesRes.data,
      source,
      target,
      algorithm,
    };

    const result = await runPathfinder(payload);

    // Persist run to history
    const runRecord = {
      map_id,
      source_node: source,
      target_node: target,
      algorithm,
      dijkstra_nodes_visited: result.dijkstra?.nodes_visited ?? null,
      dijkstra_latency_ms: result.dijkstra?.latency_ms ?? null,
      astar_nodes_visited: result.astar?.nodes_visited ?? null,
      astar_latency_ms: result.astar?.latency_ms ?? null,
    };
    await supabase.from("run_history").insert(runRecord);

    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────
// GET /api/history — recent routing sessions
// ─────────────────────────────────────────────
app.get("/api/history", async (req, res) => {
  const { data, error } = await supabase
    .from("run_history")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(20);
  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// ─────────────────────────────────────────────
// POST /api/maps/:mapId/nodes — add a node
// ─────────────────────────────────────────────
app.post("/api/maps/:mapId/nodes", async (req, res) => {
  const { mapId } = req.params;
  const { id, lat, lng, name } = req.body;
  const { data, error } = await supabase
    .from("nodes")
    .insert({ id, lat, lng, name, map_id: mapId })
    .select();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data[0]);
});

// ─────────────────────────────────────────────
// POST /api/maps/:mapId/edges — add an edge
// ─────────────────────────────────────────────
app.post("/api/maps/:mapId/edges", async (req, res) => {
  const { mapId } = req.params;
  const { from_node, to_node, weight, bidirectional = true } = req.body;
  const { data, error } = await supabase
    .from("edges")
    .insert({ from_node, to_node, weight, bidirectional, map_id: mapId })
    .select();
  if (error) return res.status(500).json({ error: error.message });
  res.json(data[0]);
});

// ─────────────────────────────────────────────
// Health check
// ─────────────────────────────────────────────
app.get("/api/health", (_, res) => res.json({ status: "ok", engine: "UrbanPath v1.0" }));

app.listen(PORT, () => {
  console.log(`\n🏙️  UrbanPath API running → http://localhost:${PORT}`);
  console.log(`   Supabase: ${process.env.SUPABASE_URL ? "✅ connected" : "⚠️  not configured"}`);
  console.log(`   C++ Engine: cpp/pathfinder (compile first)\n`);
});
