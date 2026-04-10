-- ═══════════════════════════════════════════════════════════
-- UrbanPath — Supabase PostgreSQL Schema (v2 — Pune City)
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════

-- ── Maps ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS maps (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT,
  center_lat  DOUBLE PRECISION NOT NULL,
  center_lng  DOUBLE PRECISION NOT NULL,
  zoom        INT DEFAULT 13,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── Nodes (intersections / POIs) ────────────────────────────
CREATE TABLE IF NOT EXISTS nodes (
  id         INT NOT NULL,
  map_id     UUID NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  lat        DOUBLE PRECISION NOT NULL,
  lng        DOUBLE PRECISION NOT NULL,
  name       TEXT,
  node_type  TEXT DEFAULT 'intersection', -- intersection | poi | hub
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id, map_id)
);
CREATE INDEX IF NOT EXISTS nodes_map_idx ON nodes(map_id);

-- ── Edges (road segments) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS edges (
  id            BIGSERIAL PRIMARY KEY,
  map_id        UUID NOT NULL REFERENCES maps(id) ON DELETE CASCADE,
  from_node     INT NOT NULL,
  to_node       INT NOT NULL,
  weight        DOUBLE PRECISION NOT NULL,
  bidirectional BOOLEAN DEFAULT TRUE,
  road_name     TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS edges_map_idx ON edges(map_id);

-- ── Run History ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS run_history (
  id                     BIGSERIAL PRIMARY KEY,
  map_id                 UUID REFERENCES maps(id),
  source_node            INT NOT NULL,
  target_node            INT NOT NULL,
  algorithm              TEXT NOT NULL,
  dijkstra_nodes_visited INT,
  dijkstra_latency_ms    DOUBLE PRECISION,
  astar_nodes_visited    INT,
  astar_latency_ms       DOUBLE PRECISION,
  created_at             TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- Seed: Pune Smart City Graph (15 nodes, 25 edges)
-- Based on real Pune area coordinates
-- ═══════════════════════════════════════════════════════════

INSERT INTO maps (id, name, description, center_lat, center_lng, zoom)
VALUES (
  'b0000000-0000-0000-0000-000000000001',
  'Pune Smart City',
  'Smart city routing graph covering key Pune landmarks and junctions',
  18.5204, 73.8567, 13
) ON CONFLICT DO NOTHING;

-- Nodes
INSERT INTO nodes (id, map_id, lat, lng, name, node_type) VALUES
  (1,  'b0000000-0000-0000-0000-000000000001', 18.5308, 73.8475, 'Shivajinagar Hub',    'hub'),
  (2,  'b0000000-0000-0000-0000-000000000001', 18.5156, 73.8347, 'Deccan Gymkhana',     'intersection'),
  (3,  'b0000000-0000-0000-0000-000000000001', 18.5362, 73.8938, 'Koregaon Park',       'intersection'),
  (4,  'b0000000-0000-0000-0000-000000000001', 18.5074, 73.8076, 'Kothrud Gate',        'intersection'),
  (5,  'b0000000-0000-0000-0000-000000000001', 18.5590, 73.7868, 'Baner Junction',      'intersection'),
  (6,  'b0000000-0000-0000-0000-000000000001', 18.5247, 73.8394, 'FC Road Node',        'hub'),
  (7,  'b0000000-0000-0000-0000-000000000001', 18.5018, 73.8553, 'Swargate Terminal',   'hub'),
  (8,  'b0000000-0000-0000-0000-000000000001', 18.5679, 73.9143, 'Viman Nagar',         'intersection'),
  (9,  'b0000000-0000-0000-0000-000000000001', 18.5975, 73.7617, 'Wakad Connector',     'intersection'),
  (10, 'b0000000-0000-0000-0000-000000000001', 18.5089, 73.9260, 'Hadapsar Grid',       'intersection'),
  (11, 'b0000000-0000-0000-0000-000000000001', 18.4533, 73.8643, 'Katraj Terminus',     'poi'),
  (12, 'b0000000-0000-0000-0000-000000000001', 18.5912, 73.7380, 'Hinjewadi Tech Park', 'poi'),
  (13, 'b0000000-0000-0000-0000-000000000001', 18.5127, 73.8772, 'Camp Cantonment',     'intersection'),
  (14, 'b0000000-0000-0000-0000-000000000001', 18.5621, 73.8408, 'Khadki Station',      'intersection'),
  (15, 'b0000000-0000-0000-0000-000000000001', 18.5195, 73.8553, 'MG Road Plaza',       'hub')
ON CONFLICT DO NOTHING;

-- Edges (weights in km)
INSERT INTO edges (map_id, from_node, to_node, weight, road_name) VALUES
  ('b0000000-0000-0000-0000-000000000001', 1,  2,  1.8, 'Bhandarkar Road'),
  ('b0000000-0000-0000-0000-000000000001', 1,  6,  0.9, 'FC Road Link'),
  ('b0000000-0000-0000-0000-000000000001', 1,  14, 1.4, 'Khadki Road'),
  ('b0000000-0000-0000-0000-000000000001', 2,  4,  2.1, 'Karve Road'),
  ('b0000000-0000-0000-0000-000000000001', 2,  7,  2.4, 'Tilak Road'),
  ('b0000000-0000-0000-0000-000000000001', 3,  8,  2.0, 'Airport Road'),
  ('b0000000-0000-0000-0000-000000000001', 3,  15, 1.5, 'Koregaon Bridge'),
  ('b0000000-0000-0000-0000-000000000001', 4,  5,  3.2, 'Paud Road'),
  ('b0000000-0000-0000-0000-000000000001', 5,  9,  2.6, 'Wakad Expy'),
  ('b0000000-0000-0000-0000-000000000001', 5,  12, 3.8, 'Hinjewadi Road'),
  ('b0000000-0000-0000-0000-000000000001', 6,  15, 0.7, 'FC-MG Connector'),
  ('b0000000-0000-0000-0000-000000000001', 6,  2,  1.1, 'Deccan Link'),
  ('b0000000-0000-0000-0000-000000000001', 7,  11, 3.0, 'Swargate-Katraj'),
  ('b0000000-0000-0000-0000-000000000001', 7,  13, 1.3, 'Camp Road'),
  ('b0000000-0000-0000-0000-000000000001', 8,  10, 2.2, 'Nagar Road'),
  ('b0000000-0000-0000-0000-000000000001', 8,  3,  1.8, 'Koregaon-Viman'),
  ('b0000000-0000-0000-0000-000000000001', 9,  12, 1.5, 'IT Corridor'),
  ('b0000000-0000-0000-0000-000000000001', 10, 11, 3.5, 'Hadapsar-Katraj'),
  ('b0000000-0000-0000-0000-000000000001', 10, 13, 2.8, 'Hadapsar-Camp'),
  ('b0000000-0000-0000-0000-000000000001', 13, 15, 1.0, 'MG Road'),
  ('b0000000-0000-0000-0000-000000000001', 14, 5,  4.1, 'Mumbai Highway'),
  ('b0000000-0000-0000-0000-000000000001', 14, 3,  3.6, 'Khadki-Koregaon'),
  ('b0000000-0000-0000-0000-000000000001', 15, 13, 0.9, 'Camp Connector'),
  ('b0000000-0000-0000-0000-000000000001', 15, 7,  1.8, 'MG-Swargate'),
  ('b0000000-0000-0000-0000-000000000001', 1,  3,  2.6, 'Shivaji-Koregaon')
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════════════
-- Optional: Row Level Security
-- ═══════════════════════════════════════════════════════════
-- ALTER TABLE maps ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Public read" ON maps FOR SELECT USING (true);
-- ALTER TABLE nodes ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Public read" ON nodes FOR SELECT USING (true);
-- ALTER TABLE edges ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Public read" ON edges FOR SELECT USING (true);
