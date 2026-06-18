import Foundation

enum RoutePresenter {

    static func buildRoutePresentation(pathNodeIds: [String], graph: NavigationGraph) -> RoutePresentation {
        guard !pathNodeIds.isEmpty else { return .empty }

        var segments: [RouteSegment] = []
        var transitions: [RouteTransition] = []
        var steps: [String] = []

        var currentKey = ""
        var currentBuilding = ""
        var currentFloor = ""
        var currentNodeIds: [String] = []
        var currentPoints: [MapPoint] = []

        for (index, nodeId) in pathNodeIds.enumerated() {
            guard let node = graph.nodesById[nodeId] else { continue }
            let segmentKey = "\(node.building)__\(node.floor)"

            if segmentKey != currentKey {
                if !currentNodeIds.isEmpty {
                    segments.append(RouteSegment(
                        id: currentKey, building: currentBuilding,
                        floor: currentFloor, nodeIds: currentNodeIds, points: currentPoints
                    ))
                }
                currentKey = segmentKey
                currentBuilding = node.building
                currentFloor = node.floor
                currentNodeIds = []
                currentPoints = []
            }

            currentNodeIds.append(node.id)
            currentPoints.append(MapPoint(x: node.x, y: node.y, id: node.id))

            guard index + 1 < pathNodeIds.count else { continue }
            let nextId = pathNodeIds[index + 1]
            guard let nextNode = graph.nodesById[nextId] else { continue }
            let edge = GraphBuilder.getEdge(from: graph.edgesByKey, node.id, nextId)

            if let transition = createTransition(edge: edge, from: node, to: nextNode) {
                transitions.append(transition)
            }
        }

        if !currentNodeIds.isEmpty {
            segments.append(RouteSegment(
                id: currentKey, building: currentBuilding,
                floor: currentFloor, nodeIds: currentNodeIds, points: currentPoints
            ))
        }

        buildDetailedSteps(pathNodeIds: pathNodeIds, graph: graph, steps: &steps)

        return RoutePresentation(segments: segments, transitions: transitions, steps: steps)
    }

    // MARK: - Transitions

    private static func createTransition(edge: Edge?, from fromNode: Node, to toNode: Node) -> RouteTransition? {
        guard let edge else { return nil }
        let isBuildingChange = fromNode.building != toNode.building
        let isFloorChange = fromNode.floor != toNode.floor
        guard isBuildingChange || isFloorChange else { return nil }

        return RouteTransition(
            type: isBuildingChange ? "building" : "floor",
            edgeType: edge.edgeType,
            fromNodeId: fromNode.id, toNodeId: toNode.id,
            fromBuilding: fromNode.building, toBuilding: toNode.building,
            fromFloor: fromNode.floor, toFloor: toNode.floor,
            label: edge.directionHint ?? ""
        )
    }

    // MARK: - Step descriptions

    private static func describeNodeBriefly(_ node: Node?) -> String {
        guard let node else { return "unknown" }
        switch node.type {
        case "junction": return ""
        case "room", "food": return node.label.isEmpty ? node.id : node.label
        case "toilet": return "toilet"
        case "elevator": return "elevator"
        case "staircase": return "stairs"
        case "exit": return "exit"
        default: return node.label.isEmpty ? node.id : node.label
        }
    }

    private static func describeBlock(_ block: String) -> String {
        block.isEmpty ? "" : "block \(block)"
    }

    private static func isThirdFloorExitNode(_ node: Node) -> Bool {
        node.id.contains("EXIT_1F3F")
    }

    private static func buildDetailedSteps(pathNodeIds: [String], graph: NavigationGraph, steps: inout [String]) {
        guard pathNodeIds.count >= 2 else { return }
        let nodesById = graph.nodesById

        let startNode = nodesById[pathNodeIds[0]]!
        let endNode = nodesById[pathNodeIds[pathNodeIds.count - 1]]!

        steps.append("Start from \(describeNodeBriefly(startNode)) (\(startNode.floor) \(describeBlock(startNode.block)))")

        var i = 0
        while i < pathNodeIds.count - 1 {
            let node = nodesById[pathNodeIds[i]]!
            let nextNode = nodesById[pathNodeIds[i + 1]]!
            let edge = GraphBuilder.getEdge(from: graph.edgesByKey, node.id, nextNode.id)

            if let edge, edge.edgeType == "elevator" {
                let fromFloor = node.floor
                var toFloor = nextNode.floor
                var j = i + 1
                while j < pathNodeIds.count - 1 {
                    if let e = GraphBuilder.getEdge(from: graph.edgesByKey, pathNodeIds[j], pathNodeIds[j + 1]),
                       e.edgeType == "elevator" {
                        toFloor = nodesById[pathNodeIds[j + 1]]!.floor
                        j += 1
                    } else { break }
                }
                steps.append("Take the elevator from \(fromFloor) to \(toFloor)")
                i = j
                continue
            }

            if let edge, edge.edgeType == "staircase" {
                let fromFloor = node.floor
                var toFloor = nextNode.floor
                var j = i + 1
                var usesThirdFloorExit = isThirdFloorExitNode(node) || isThirdFloorExitNode(nextNode)
                while j < pathNodeIds.count - 1 {
                    if let e = GraphBuilder.getEdge(from: graph.edgesByKey, pathNodeIds[j], pathNodeIds[j + 1]),
                       e.edgeType == "staircase" {
                        let nextN = nodesById[pathNodeIds[j + 1]]!
                        usesThirdFloorExit = usesThirdFloorExit || isThirdFloorExitNode(nextN)
                        toFloor = nextN.floor
                        j += 1
                    } else { break }
                }
                if usesThirdFloorExit {
                    steps.append("Use the 3F entrance/exit from \(fromFloor) to \(toFloor)")
                } else {
                    steps.append("Take the stairs from \(fromFloor) to \(toFloor)")
                }
                i = j
                continue
            }

            if let edge, edge.edgeType == "tunnel" {
                steps.append("Use the tunnel from building \(node.building) to building \(nextNode.building)")
                i += 1
                continue
            }

            let walkResult = collectWalkSegment(pathNodeIds: pathNodeIds, startIdx: i, graph: graph)
            if walkResult.endIndex > i {
                let desc = describeWalkSegment(walkResult, graph: graph)
                if !desc.isEmpty { steps.append(desc) }
                i = walkResult.endIndex
                continue
            }

            i += 1
        }

        steps.append("Arrive at \(describeNodeBriefly(endNode)) (\(endNode.floor) \(describeBlock(endNode.block)))")
    }

    // MARK: - Walk segment

    private struct WalkSegmentResult {
        let startIndex: Int
        let endIndex: Int
        let startNode: Node
        let endNode: Node
        let visitedLandmarks: [Node]
        let totalDistance: Double
        let directions: [String]
    }

    private static func collectWalkSegment(pathNodeIds: [String], startIdx: Int,
                                           graph: NavigationGraph) -> WalkSegmentResult {
        let nodesById = graph.nodesById
        var i = startIdx
        var visitedLandmarks: [Node] = []
        var totalDistance = 0.0
        var directions: [String] = []

        while i < pathNodeIds.count - 1 {
            let node = nodesById[pathNodeIds[i]]!
            let nextNode = nodesById[pathNodeIds[i + 1]]!
            guard let edge = GraphBuilder.getEdge(from: graph.edgesByKey, node.id, nextNode.id),
                  edge.edgeType == "flat" else { break }

            if node.type != "junction" && i > startIdx {
                visitedLandmarks.append(node)
            }
            if let hint = edge.directionHint, !hint.isEmpty {
                directions.append(hint)
            }
            totalDistance += edge.distance
            i += 1
        }

        return WalkSegmentResult(
            startIndex: startIdx, endIndex: i,
            startNode: nodesById[pathNodeIds[startIdx]]!,
            endNode: nodesById[pathNodeIds[i]]!,
            visitedLandmarks: visitedLandmarks,
            totalDistance: totalDistance,
            directions: directions
        )
    }

    private static func describeWalkSegment(_ result: WalkSegmentResult, graph: NavigationGraph) -> String {
        let startNode = result.startNode
        let endNode = result.endNode
        guard startNode.id != endNode.id else { return "" }

        let mainDirection = getMajorDirection(result.directions)
        let dirText = mainDirection
        let startDesc = describeNodeBriefly(startNode)
        let endDesc = describeNodeBriefly(endNode)
        let startIsJunction = startNode.type == "junction"
        let endIsJunction = endNode.type == "junction"

        if startIsJunction && endIsJunction {
            return "Walk \(dirText) along the corridor"
        }
        if startIsJunction && !endIsJunction {
            return "Go \(dirText) to \(endDesc)"
        }
        if !startIsJunction && endIsJunction {
            return "From \(startDesc), walk \(dirText) along the corridor"
        }

        var passBy = ""
        let landmarkNames = result.visitedLandmarks
            .filter { $0.type != "junction" }
            .compactMap { n -> String? in
                let desc = describeNodeBriefly(n)
                return desc.isEmpty ? nil : desc
            }
            .prefix(2)
        if !landmarkNames.isEmpty {
            passBy = ", passing \(landmarkNames.joined(separator: " and "))"
        }

        return "Go \(dirText) to \(endDesc)\(passBy)"
    }

    private static func getMajorDirection(_ directions: [String]) -> String {
        guard !directions.isEmpty else { return "" }
        var counts: [String: Int] = [:]
        for d in directions { counts[d, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key ?? ""
    }
}
