# 🏙️ UrbanPath — Pune Smart City Routing System

> Real-time pathfinding visualizer comparing **Dijkstra** vs **A\*** on a live **Pune city graph** — with a full responsive cyber dashboard for Android and laptop.

![Stack](https://img.shields.io/badge/Frontend-HTML%20%7C%20Leaflet.js%20%7C%20TailwindCSS-00f5ff?style=flat-square)
![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-39ff14?style=flat-square)
![Engine](https://img.shields.io/badge/Engine-C%2B%2B17-bf5af2?style=flat-square)
![DB](https://img.shields.io/badge/Database-Supabase%20%7C%20PostgreSQL-ffb703?style=flat-square)

---

## 📁 Project Structure

```
urbanpath/
├── frontend/
│   └── index.html           ← Responsive cyber dashboard (Leaflet + Tailwind)
├── backend/
│   ├── server.js             ← Node.js API gateway (Express)
│   ├── package.json
│   └── .env.example
├── cpp/
│   ├── pathfinder.cpp        ← C++ Dijkstra + A* engine
│   └── Makefile
├── database/
│   └── schema.sql            ← Supabase schema + Pune city seed data
└── README.md
```

---

## 🗺️ Pune City Graph

The built-in city graph includes **15 real Pune landmarks** and **25 road edges**:

| # | Node | Area |
|---|------|------|
| 1 | Shivajinagar Hub | Central Pune |
| 2 | Deccan Gymkhana | West Pune |
| 3 | Koregaon Park | East Pune |
| 4 | Kothrud Gate | West Pune |
| 5 | Baner Junction | NW Pune |
| 6 | FC Road Node | Central |
| 7 | Swargate Terminal | South Pune |
| 8 | Viman Nagar | NE Pune |
| 9 | Wakad Connector | Far NW |
| 10 | Hadapsar Grid | SE Pune |
| 11 | Katraj Terminus | South end |
| 12 | Hinjewadi Tech Park | Far West |
| 13 | Camp Cantonment | Central-East |
| 14 | Khadki Station | North |
| 15 | MG Road Plaza | Central |

---

## 📱 Responsive Layout

### Laptop / Desktop (≥ 769px)
```
┌─────────────┬─────────────────────────────┬─────────────┐
│   COMMAND   │                             │   METRICS   │
│   PANEL     │        LEAFLET MAP          │   COMPARE   │
│   (260px)   │       (full center)         │    LOG      │
│             │                             │   (260px)   │
└─────────────┴─────────────────────────────┴─────────────┘
```

### Android / Mobile (≤ 768px)
```
┌─────────────────────────────────────┐
│            HEADER BAR               │
├─────────────────────────────────────┤
│                                     │
│         FULL SCREEN MAP             │
│      (tap nodes directly)           │
│                                     │
├──────────────────────────┬──────────┤
│  ════ BOTTOM SHEET ════  │  drag ↕  │
│  CONTROL │ STATS │ LOG   │          │
└──────────────────────────┴──────────┘
│  MAP  │  CONTROL  │  STATS  │  LOG  │  ← Bottom nav
└───────────────────────────────────────┘
```

The bottom sheet supports **drag gestures**: swipe up to expand, swipe down to collapse. Tap bottom nav buttons to switch panels instantly.

---

## 🚀 Quick Start

### 1. Open Immediately (No Backend)
```
Open frontend/index.html in any browser
→ Click "◈ DEMO (OFFLINE)" — runs full Pune graph in-browser
```

### 2. Full Stack Setup

**Supabase:**
1. Create project at [supabase.com](https://supabase.com)
2. SQL Editor → paste `database/schema.sql` → Run
3. Copy Project URL + anon key

**Backend:**
```bash
cd backend
cp .env.example .env      # fill in Supabase credentials
npm install
npm start                  # → http://localhost:3000
```

**C++ Engine:**
```bash
cd cpp
make                       # auto-downloads nlohmann/json, compiles
# OR manually:
curl -L https://github.com/nlohmann/json/releases/download/v3.11.3/json.hpp -o json.hpp
g++ -O2 -std=c++17 -o pathfinder pathfinder.cpp
```

**Open Frontend:**
```
http://localhost:3000
```

---

## 🎮 How to Use

### Select Nodes
- **Tap directly on map** — first tap = Source (green), second tap = Target (red)
- **Or use dropdowns** — Source / Target selects in Command panel

### Run Algorithms
1. Select algorithm: **BOTH** | **DIJKSTRA** | **A★**
2. Adjust animation speed: SLOW → NORMAL → FAST → TURBO
3. Click **⚡ EXECUTE** (or **⚡ RUN** on mobile)

### Read Results
- **Purple dots** = nodes visited during exploration
- **Cyan solid line** = Dijkstra's path
- **Green dashed line** = A★ path
- Check **METRICS** tab for node count, latency, cost
- Check **COMPARE** tab for side-by-side bar charts + analysis

---

## 🔬 Algorithm Details

### Dijkstra
- Explores all reachable nodes in order of cost
- Guaranteed shortest path, O((V+E) log V)
- "Blind" — no directional bias toward target

### A★
- f(n) = g(n) + h(n) where h = Euclidean distance × 111 km/degree
- Focuses search toward target — prunes unnecessary nodes
- Same optimal path, significantly fewer expansions on sparse graphs

---

## 🔌 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/maps` | List all city maps |
| GET | `/api/maps/:id/graph` | Load nodes + edges |
| POST | `/api/route` | Run pathfinding |
| GET | `/api/history` | Recent runs |
| GET | `/api/health` | Health check |

**POST /api/route body:**
```json
{ "map_id": "uuid", "source": 1, "target": 11, "algorithm": "both" }
```

---

## 🖥️ C++ Engine

Reads JSON from stdin, outputs results to stdout:
```bash
echo '{"nodes":[...],"edges":[...],"source":1,"target":11,"algorithm":"both"}' | ./pathfinder
```

Each result includes: `path[]`, `visited_order[]`, `total_cost`, `nodes_visited`, `latency_ms`

---

## 📦 Dependencies

| Layer | Dependencies |
|-------|-------------|
| Frontend | Leaflet.js 1.9.4, Tailwind CSS CDN, Orbitron + Share Tech Mono fonts |
| Backend | express, @supabase/supabase-js, cors, dotenv |
| C++ | nlohmann/json (auto-downloaded), C++17 STL |

---

*UrbanPath v2 — Pune Smart City Routing Engine*
