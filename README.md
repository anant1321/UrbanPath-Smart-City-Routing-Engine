# 🏙️ UrbanPath — Pune Smart City Routing System

> A real-time pathfinding visualization engine comparing **Dijkstra** vs **A\*** on Pune's actual road network — built as a full-stack smart city project by a team of four.

![Stack](https://img.shields.io/badge/Frontend-HTML%20%7C%20Leaflet.js%20%7C%20Tailwind-00f5ff?style=flat-square)
![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-39ff14?style=flat-square)
![Engine](https://img.shields.io/badge/Engine-C%2B%2B17-bf5af2?style=flat-square)
![DB](https://img.shields.io/badge/Database-Supabase%20%7C%20PostgreSQL-ffb703?style=flat-square)

---

## 👥 Team

| Name | Role |
|------|------|
| **Anant** | Full-Stack Lead, Algorithm Engine, Frontend, Backend |
| **Raghav Vyavahare** | Graph Modeling & Data Layer |
| **Soham Kulkarni** | Frontend UI & Visualization |
| **Bala Jee** | Backend API & Database Integration |

---

## 💡 Motivation

Living in a fast-growing city like Pune, we kept wondering how smarter algorithms could make navigation more efficient at scale — for autonomous logistics, emergency response, and smart traffic systems. That question became UrbanPath.

---

## 🗺️ What It Does

UrbanPath maps **35 key Pune city nodes** and **145 weighted road segments** onto an interactive Leaflet.js dashboard, then runs **Dijkstra's Algorithm** and **A\* Search** side-by-side on any chosen route — animating every node explored so you can literally watch the heuristic prune the search space in real time.

### Key Results

In one benchmark test (Shivajinagar → Katraj):

| Metric | Dijkstra | A★ |
|--------|----------|----|
| Nodes explored | 19 | 5 |
| Path cost | 6.4 km | 6.4 km |
| Latency | higher | lower |

**Same optimal path. 74% fewer node expansions.** That's the heuristic advantage — `f(n) = g(n) + h(n)` — made visible.

---

## ✨ Features

- 🗺️ **Interactive map** — click nodes directly on Leaflet.js + OpenStreetMap to set source and target
- ⚡ **Real-time comparison** — Dijkstra and A\* run simultaneously with animated node exploration
- 📊 **Live metrics** — nodes visited, path cost (km), latency (ms), efficiency gain %
- 🟣 **Visual search space** — purple sweep shows explored nodes; cyan/green lines show final paths
- 🗄️ **Route history** — every run persisted to Supabase PostgreSQL
- 📱 **Responsive** — full cyber dashboard for desktop and Android (bottom-sheet navigation)
- 🔌 **Offline demo** — built-in Pune graph runs client-side with zero backend

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | HTML5, Tailwind CSS, JavaScript, Leaflet.js |
| Backend | Node.js, Express.js |
| Algorithm Engine | C++ STL (MinHeap PQ, O((V+E) log V)) |
| Database | Supabase / PostgreSQL |
| Deployment | Vercel (serverless) + GitHub CI/CD |
| Algorithms | Dijkstra's Algorithm, A\* Search (Euclidean heuristic) |

---

## 📁 Project Structure

```
urbanpath/
├── public/
│   └── index.html              ← Cyber dashboard (Leaflet + Tailwind)
├── api/
│   ├── _supabase.js            ← Shared Supabase client + CORS
│   ├── _pathfinder.js          ← Dijkstra + A* (Node.js, Vercel-ready)
│   ├── maps.js                 ← GET  /api/maps
│   ├── maps/[mapId]/graph.js   ← GET  /api/maps/:id/graph
│   ├── route.js                ← POST /api/route
│   ├── history.js              ← GET  /api/history
│   └── health.js               ← GET  /api/health
├── cpp/
│   ├── pathfinder.cpp          ← C++ engine (local/server use)
│   └── Makefile
├── database/
│   └── schema.sql              ← Supabase schema + Pune city seed
├── vercel.json
├── package.json
├── DEPLOY.md                   ← Step-by-step Vercel deployment guide
└── README.md
```

---

## 🚀 Quick Start

### Option 1 — Instant Demo (No Setup)
```
Open public/index.html in any browser
→ Click ◈ DEMO (OFFLINE) to run Pune pathfinding entirely in-browser
```

### Option 2 — Full Stack

**1. Supabase**
```
supabase.com → New Project → SQL Editor → paste database/schema.sql → Run
Copy your Project URL and anon key
```

**2. Backend**
```bash
npm install
# create .env with SUPABASE_URL and SUPABASE_ANON_KEY
node api/server.js        # or: vercel dev
```

**3. C++ Engine (optional, local only)**
```bash
cd cpp
make                      # auto-downloads nlohmann/json, compiles
./pathfinder              # test with JSON on stdin
```

**4. Deploy to Vercel**
```bash
git push origin main      # Vercel auto-deploys on every push
```
→ See **[DEPLOY.md](./DEPLOY.md)** for the full step-by-step guide.

---

## 🔬 Algorithm Details

### Dijkstra's Algorithm
- Uninformed (blind) search — explores all directions equally
- Guaranteed shortest path: `O((V + E) log V)` with a min-heap priority queue
- Weakness: examines many nodes that are far from the target

### A\* Search
- Informed search — guided by heuristic `h(n) = Euclidean distance × 111 km/degree`
- Priority function: `f(n) = g(n) + h(n)` where `g(n)` = actual cost from source
- Result: same optimal path as Dijkstra, with significantly fewer node expansions

---

## 🗄️ Database Schema

| Table | Description |
|-------|-------------|
| `maps` | City map configurations (center, zoom) |
| `nodes` | Intersections with real lat/lng coordinates |
| `edges` | Road segments with km weights and road names |
| `run_history` | Algorithm performance log per session |

---

## 🔌 API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/maps` | List all city maps |
| GET | `/api/maps/:id/graph` | Load nodes + edges |
| POST | `/api/route` | Run pathfinding algorithms |
| GET | `/api/history` | Recent routing sessions |
| GET | `/api/health` | Service health check |

**POST `/api/route` body:**
```json
{
  "map_id": "uuid",
  "source": 1,
  "target": 11,
  "algorithm": "both"
}
```

---

## 🗺️ Pune City Graph

35 real Pune landmarks connected by 145 weighted road segments, including:

- Shivajinagar Hub · FC Road · Deccan Gymkhana · Koregaon Park
- Baner Junction · Hinjewadi Tech Park · Wakad · Khadki Station
- MG Road · Camp Cantonment · Viman Nagar · Hadapsar
- Swargate · Katraj Terminus · Kothrud · and more

---

## 🔮 Roadmap

- [ ] Real-time traffic weight updates
- [ ] ML-based congestion prediction (XGBoost / LSTM)
- [ ] Bidirectional A\* for even faster convergence
- [ ] Expand to 100+ node graph (full PMC area)
- [ ] Multi-stop routing (TSP approximation)
- [ ] Public API for third-party smart city integrations

---

*Built with ❤️ by Anant, Raghav Vyavahare, Soham Kulkarni & Bala Jee — MIT World Peace University, Pune*
