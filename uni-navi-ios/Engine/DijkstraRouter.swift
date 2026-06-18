import Foundation

enum DijkstraRouter {

    // MARK: - Core shortest path

    static func shortestPath(graph: NavigationGraph, startId: String, endId: String) -> PathResult {
        shortestPathExcluding(graph: graph, startId: startId, endId: endId, excludeEdgeTypes: nil)
    }

    static func shortestPathFlatOnly(graph: NavigationGraph, startId: String, endId: String) -> PathResult {
        shortestPathExcluding(graph: graph, startId: startId, endId: endId,
                              excludeEdgeTypes: Set(["elevator", "staircase", "tunnel"]))
    }

    static func shortestPathExcluding(
        graph: NavigationGraph, startId: String, endId: String, excludeEdgeTypes: Set<String>?
    ) -> PathResult {
        let nodesById = graph.nodesById
        let adjacency = graph.adjacency

        guard nodesById[startId] != nil, nodesById[endId] != nil else {
            return .empty
        }

        var distances: [String: Double] = [:]
        var previous: [String: String?] = [:]
        var visited = Set<String>()

        for nodeId in nodesById.keys {
            distances[nodeId] = .infinity
            previous[nodeId] = nil
        }
        distances[startId] = 0

        while true {
            var current: String?
            var minDist = Double.infinity

            for (nodeId, dist) in distances where !visited.contains(nodeId) && dist < minDist {
                minDist = dist
                current = nodeId
            }

            guard let cur = current, minDist < .infinity else { break }
            if cur == endId { break }

            visited.insert(cur)

            for neighbor in adjacency[cur] ?? [] {
                if visited.contains(neighbor.to) { continue }
                if let excluded = excludeEdgeTypes, excluded.contains(neighbor.edge.edgeType) { continue }
                let candidate = distances[cur]! + neighbor.edge.distance
                if candidate < distances[neighbor.to]! {
                    distances[neighbor.to] = candidate
                    previous[neighbor.to] = cur
                }
            }
        }

        guard let endDist = distances[endId], endDist < .infinity else {
            return .empty
        }

        var path: [String] = []
        var walker: String? = endId
        while let w = walker {
            path.insert(w, at: 0)
            walker = previous[w] ?? nil
        }

        return PathResult(path: path, distance: endDist)
    }

    // MARK: - Vertical shaft identification

    struct Shaft {
        let nodes: [String]
        let nodesByFloor: [String: String]
        let transportType: String
        let kind: ShaftKind
    }

    enum ShaftKind: String {
        case elevator
        case stair
        case externalZeroFloorStair
        case thirdFloorExit
    }

    private static func getShaftKind(nodeIds: [String], transportType: String) -> ShaftKind {
        for id in nodeIds {
            if id.contains("EXIT_1F3F") { return .thirdFloorExit }
            if id.contains("EXT_STAIR_") { return .externalZeroFloorStair }
        }
        return transportType == "elevator" ? .elevator : .stair
    }

    private static func modePriority(mode: RouteMode, kind: ShaftKind) -> Int {
        switch mode {
        case .comfort:
            switch kind {
            case .elevator: return 0
            case .stair, .externalZeroFloorStair: return 1
            case .thirdFloorExit: return 3
            }
        case .fast:
            switch kind {
            case .stair, .externalZeroFloorStair: return 0
            case .thirdFloorExit: return 2
            case .elevator: return 3
            }
        }
    }

    static func identifyShafts(graph: NavigationGraph, transportType: String) -> [Shaft] {
        var vertAdj: [String: [String]] = [:]
        for e in graph.edges where e.edgeType == transportType {
            vertAdj[e.from, default: []].append(e.to)
            vertAdj[e.to, default: []].append(e.from)
        }

        var visited = Set<String>()
        var shafts: [Shaft] = []

        for startNode in vertAdj.keys where !visited.contains(startNode) {
            var component: [String] = []
            var queue = [startNode]
            visited.insert(startNode)

            while !queue.isEmpty {
                let cur = queue.removeFirst()
                component.append(cur)
                for neighbor in vertAdj[cur] ?? [] where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    queue.append(neighbor)
                }
            }

            var nodesByFloor: [String: String] = [:]
            for nodeId in component {
                if let node = graph.nodesById[nodeId] {
                    nodesByFloor[node.floor] = nodeId
                }
            }

            let kind = getShaftKind(nodeIds: component, transportType: transportType)
            shafts.append(Shaft(nodes: component, nodesByFloor: nodesByFloor,
                                transportType: transportType, kind: kind))
        }

        return shafts
    }

    private static func getShaftPath(graph: NavigationGraph, shaft: Shaft,
                                     fromFloor: String, toFloor: String) -> PathResult {
        let floorOrder = MapConstants.floorOrder
        let floors = shaft.nodesByFloor.keys.sorted {
            (floorOrder.firstIndex(of: $0) ?? 99) < (floorOrder.firstIndex(of: $1) ?? 99)
        }

        guard let fromIdx = floors.firstIndex(of: fromFloor),
              let toIdx = floors.firstIndex(of: toFloor) else {
            return .empty
        }

        let step = fromIdx < toIdx ? 1 : -1
        var path: [String] = []
        var distance = 0.0

        var i = fromIdx
        while true {
            let nodeId = shaft.nodesByFloor[floors[i]]!
            path.append(nodeId)
            if i != fromIdx {
                let prevIdx = floors.index(i, offsetBy: -step)
                let prevId = shaft.nodesByFloor[floors[prevIdx]]!
                if let edge = GraphBuilder.getEdge(from: graph.edgesByKey, prevId, nodeId) {
                    distance += edge.distance
                } else {
                    distance += 20
                }
            }
            if i == toIdx { break }
            i += step
        }

        return PathResult(path: path, distance: distance)
    }

    // MARK: - Preferred route (comfort / fast)

    static func findPreferredRoute(graph: NavigationGraph, startId: String,
                                   endId: String, mode: RouteMode) -> PathResult {
        let nodesById = graph.nodesById
        guard let startNode = nodesById[startId], let endNode = nodesById[endId] else {
            return .empty
        }

        if startNode.floor == endNode.floor {
            return shortestPathFlatOnly(graph: graph, startId: startId, endId: endId)
        }

        let shafts = identifyShafts(graph: graph, transportType: "elevator")
                   + identifyShafts(graph: graph, transportType: "staircase")

        var best: (path: [String], distance: Double, kind: ShaftKind, priority: Int)?

        for shaft in shafts {
            if shaft.kind == .externalZeroFloorStair && endNode.floor != "0F" { continue }

            guard let entryId = shaft.nodesByFloor[startNode.floor],
                  let exitId = shaft.nodesByFloor[endNode.floor] else { continue }

            let leg1 = shortestPathFlatOnly(graph: graph, startId: startId, endId: entryId)
            guard leg1.distance < .infinity else { continue }

            let leg2 = getShaftPath(graph: graph, shaft: shaft,
                                    fromFloor: startNode.floor, toFloor: endNode.floor)
            guard leg2.distance < .infinity else { continue }

            let leg3 = shortestPathFlatOnly(graph: graph, startId: exitId, endId: endId)
            guard leg3.distance < .infinity else { continue }

            let totalDist = leg1.distance + leg2.distance + leg3.distance
            let priority = modePriority(mode: mode, kind: shaft.kind)

            var combined = leg1.path
            combined.append(contentsOf: leg2.path.dropFirst())
            combined.append(contentsOf: leg3.path.dropFirst())

            let isBetter: Bool
            if let b = best {
                if mode == .fast {
                    isBetter = totalDist < b.distance ||
                               (totalDist == b.distance && priority < b.priority)
                } else {
                    isBetter = priority < b.priority ||
                               (priority == b.priority && totalDist < b.distance)
                }
            } else {
                isBetter = true
            }

            if isBetter {
                best = (combined, totalDist, shaft.kind, priority)
            }
        }

        if let best {
            return PathResult(path: best.path, distance: best.distance, routeKind: best.kind.rawValue)
        }

        return PathResult(path: [], distance: .infinity)
    }
}
