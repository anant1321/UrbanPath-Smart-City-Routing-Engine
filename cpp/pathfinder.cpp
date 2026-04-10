#include <iostream>
#include <vector>
#include <queue>
#include <unordered_map>
#include <cmath>
#include <chrono>
#include <limits>
#include <algorithm>
#include <string>
#include <sstream>
#include "json.hpp"

using namespace std;
using json = nlohmann::json;

// ─────────────────────────────────────────────
// Data Structures
// ─────────────────────────────────────────────

struct Node {
    int id;
    double lat, lng;
    string name;
};

struct Edge {
    int to;
    double weight;
};

struct PathResult {
    vector<int> path;
    vector<int> visited_order;
    double total_cost;
    int nodes_visited;
    double latency_ms;
    bool found;
};

// ─────────────────────────────────────────────
// Graph
// ─────────────────────────────────────────────

class CityGraph {
public:
    unordered_map<int, Node> nodes;
    unordered_map<int, vector<Edge>> adj;

    void addNode(int id, double lat, double lng, const string& name = "") {
        nodes[id] = {id, lat, lng, name};
    }

    void addEdge(int u, int v, double weight, bool bidirectional = true) {
        adj[u].push_back({v, weight});
        if (bidirectional) adj[v].push_back({u, weight});
    }

    double euclideanHeuristic(int a, int b) const {
        const Node& na = nodes.at(a);
        const Node& nb = nodes.at(b);
        double dlat = na.lat - nb.lat;
        double dlng = na.lng - nb.lng;
        // Haversine-inspired flat approximation (fast for small city areas)
        return sqrt(dlat * dlat + dlng * dlng) * 111.0; // ~km
    }
};

// ─────────────────────────────────────────────
// Dijkstra
// ─────────────────────────────────────────────

PathResult dijkstra(const CityGraph& graph, int source, int target) {
    auto start_time = chrono::high_resolution_clock::now();

    unordered_map<int, double> dist;
    unordered_map<int, int> prev;
    vector<int> visited_order;

    for (auto& [id, _] : graph.nodes) dist[id] = numeric_limits<double>::infinity();
    dist[source] = 0.0;

    // {cost, node}
    priority_queue<pair<double,int>, vector<pair<double,int>>, greater<>> pq;
    pq.push({0.0, source});

    unordered_map<int, bool> visited;

    while (!pq.empty()) {
        auto [cost, u] = pq.top(); pq.pop();
        if (visited[u]) continue;
        visited[u] = true;
        visited_order.push_back(u);

        if (u == target) break;

        if (graph.adj.count(u)) {
            for (const Edge& e : graph.adj.at(u)) {
                double newDist = dist[u] + e.weight;
                if (newDist < dist[e.to]) {
                    dist[e.to] = newDist;
                    prev[e.to] = u;
                    pq.push({newDist, e.to});
                }
            }
        }
    }

    auto end_time = chrono::high_resolution_clock::now();
    double latency = chrono::duration<double, milli>(end_time - start_time).count();

    PathResult result;
    result.nodes_visited = visited_order.size();
    result.latency_ms = latency;
    result.visited_order = visited_order;

    if (dist.count(target) && dist[target] != numeric_limits<double>::infinity()) {
        result.found = true;
        result.total_cost = dist[target];
        // Reconstruct path
        int cur = target;
        while (cur != source) {
            result.path.push_back(cur);
            cur = prev[cur];
        }
        result.path.push_back(source);
        reverse(result.path.begin(), result.path.end());
    } else {
        result.found = false;
        result.total_cost = -1;
    }

    return result;
}

// ─────────────────────────────────────────────
// A* Search
// ─────────────────────────────────────────────

PathResult astar(const CityGraph& graph, int source, int target) {
    auto start_time = chrono::high_resolution_clock::now();

    unordered_map<int, double> g_score, f_score;
    unordered_map<int, int> prev;
    vector<int> visited_order;

    for (auto& [id, _] : graph.nodes) {
        g_score[id] = numeric_limits<double>::infinity();
        f_score[id] = numeric_limits<double>::infinity();
    }
    g_score[source] = 0.0;
    f_score[source] = graph.euclideanHeuristic(source, target);

    // {f_score, node}
    priority_queue<pair<double,int>, vector<pair<double,int>>, greater<>> open;
    open.push({f_score[source], source});

    unordered_map<int, bool> closed;

    while (!open.empty()) {
        auto [f, u] = open.top(); open.pop();
        if (closed[u]) continue;
        closed[u] = true;
        visited_order.push_back(u);

        if (u == target) break;

        if (graph.adj.count(u)) {
            for (const Edge& e : graph.adj.at(u)) {
                if (closed[e.to]) continue;
                double tentative_g = g_score[u] + e.weight;
                if (tentative_g < g_score[e.to]) {
                    prev[e.to] = u;
                    g_score[e.to] = tentative_g;
                    f_score[e.to] = tentative_g + graph.euclideanHeuristic(e.to, target);
                    open.push({f_score[e.to], e.to});
                }
            }
        }
    }

    auto end_time = chrono::high_resolution_clock::now();
    double latency = chrono::duration<double, milli>(end_time - start_time).count();

    PathResult result;
    result.nodes_visited = visited_order.size();
    result.latency_ms = latency;
    result.visited_order = visited_order;

    if (g_score.count(target) && g_score[target] != numeric_limits<double>::infinity()) {
        result.found = true;
        result.total_cost = g_score[target];
        int cur = target;
        while (cur != source) {
            result.path.push_back(cur);
            cur = prev[cur];
        }
        result.path.push_back(source);
        reverse(result.path.begin(), result.path.end());
    } else {
        result.found = false;
        result.total_cost = -1;
    }

    return result;
}

// ─────────────────────────────────────────────
// Main: Read JSON from stdin, output JSON to stdout
// ─────────────────────────────────────────────

int main() {
    try {
        json input;
        cin >> input;

        CityGraph graph;

        // Load nodes
        for (auto& n : input["nodes"]) {
            graph.addNode(
                n["id"].get<int>(),
                n["lat"].get<double>(),
                n["lng"].get<double>(),
                n.value("name", "")
            );
        }

        // Load edges
        for (auto& e : input["edges"]) {
            graph.addEdge(
                e["from"].get<int>(),
                e["to"].get<int>(),
                e["weight"].get<double>(),
                e.value("bidirectional", true)
            );
        }

        int source = input["source"].get<int>();
        int target = input["target"].get<int>();
        string algo = input.value("algorithm", "both");

        json output;

        auto serializeResult = [](const PathResult& r, const string& name) {
            json j;
            j["algorithm"] = name;
            j["found"] = r.found;
            j["path"] = r.path;
            j["visited_order"] = r.visited_order;
            j["total_cost"] = r.total_cost;
            j["nodes_visited"] = r.nodes_visited;
            j["latency_ms"] = r.latency_ms;
            return j;
        };

        if (algo == "dijkstra" || algo == "both") {
            PathResult dr = dijkstra(graph, source, target);
            output["dijkstra"] = serializeResult(dr, "Dijkstra");
        }
        if (algo == "astar" || algo == "both") {
            PathResult ar = astar(graph, source, target);
            output["astar"] = serializeResult(ar, "A*");
        }

        cout << output.dump(2) << endl;

    } catch (const exception& ex) {
        json err;
        err["error"] = ex.what();
        cout << err.dump() << endl;
        return 1;
    }

    return 0;
}
