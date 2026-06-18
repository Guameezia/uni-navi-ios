import Foundation

struct NavigationGraph {
    let nodesById: [String: Node]
    let adjacency: [String: [(to: String, edge: Edge)]]
    let edgesByKey: [String: Edge]
    let edges: [Edge]
    let buildings: [String: [String]]
}

enum GraphBuilder {
    static func edgeKey(_ a: String, _ b: String) -> String {
        a < b ? "\(a)__\(b)" : "\(b)__\(a)"
    }

    static func getEdge(from edgesByKey: [String: Edge], _ fromId: String, _ toId: String) -> Edge? {
        edgesByKey[edgeKey(fromId, toId)]
    }

    static func createGraph(enabledBuildings: [String] = ["S"]) -> NavigationGraph {
        let allNodes = loadNodes(for: enabledBuildings)
        let allEdges = loadEdges(for: enabledBuildings)

        var nodesById: [String: Node] = [:]
        var adjacency: [String: [(to: String, edge: Edge)]] = [:]
        var buildings: [String: [String]] = [:]

        for node in allNodes {
            nodesById[node.id] = node
            adjacency[node.id] = []
            buildings[node.building, default: []].append(node.id)
        }

        var edgesByKey: [String: Edge] = [:]
        var includedEdges: [Edge] = []

        for edge in allEdges {
            guard nodesById[edge.from] != nil, nodesById[edge.to] != nil else { continue }
            includedEdges.append(edge)
            adjacency[edge.from, default: []].append((to: edge.to, edge: edge))
            adjacency[edge.to, default: []].append((to: edge.from, edge: edge))
            edgesByKey[edgeKey(edge.from, edge.to)] = edge
        }

        return NavigationGraph(
            nodesById: nodesById,
            adjacency: adjacency,
            edgesByKey: edgesByKey,
            edges: includedEdges,
            buildings: buildings
        )
    }

    static func getLandmarkNodes(from nodesById: [String: Node]) -> [Node] {
        nodesById.values
            .filter(\.isLandmark)
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    private static func loadNodes(for buildings: [String]) -> [Node] {
        buildings.flatMap { loadJSON(resource: "nodes", subdirectory: "Resources/Data/\($0)") as [Node] }
    }

    private static func loadEdges(for buildings: [String]) -> [Edge] {
        buildings.flatMap { loadJSON(resource: "edges", subdirectory: "Resources/Data/\($0)") as [Edge] }
    }

    private static func loadJSON<T: Decodable>(resource: String, subdirectory: String) -> [T] {
        let url = Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: resource, withExtension: "json")
        guard let url else {
            print("[UniNavi] Missing resource: \(subdirectory)/\(resource).json")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("[UniNavi] Failed to decode \(resource).json: \(error)")
            return []
        }
    }
}
