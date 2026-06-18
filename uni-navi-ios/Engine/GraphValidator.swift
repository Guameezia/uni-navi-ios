import Foundation

enum GraphValidator {
    static let allowedFloors = ["0F", "1F", "2F", "3F", "4F", "5F"]
    static let sBlocks = ["SA", "SB", "SC", "SD"]

    struct ValidationResult {
        let ok: Bool
        let errors: [String]
    }

    static func validate(nodes: [Node], edges: [Edge]) -> ValidationResult {
        var errors: [String] = []
        var nodeIds = Set<String>()
        var nodesById: [String: Node] = [:]

        for node in nodes {
            if nodeIds.contains(node.id) {
                errors.append("Duplicate node id: \(node.id)")
            }
            nodeIds.insert(node.id)
            nodesById[node.id] = node

            if !allowedFloors.contains(node.floor) {
                errors.append("Invalid floor \"\(node.floor)\" on node \(node.id)")
            }
            if node.building.isEmpty {
                errors.append("Missing building code on node \(node.id)")
            }
        }

        for (idx, edge) in edges.enumerated() {
            guard let fromNode = nodesById[edge.from] else {
                errors.append("Edge[\(idx)] invalid from node: \(edge.from)")
                continue
            }
            guard let toNode = nodesById[edge.to] else {
                errors.append("Edge[\(idx)] invalid to node: \(edge.to)")
                continue
            }

            let sameFloor = fromNode.floor == toNode.floor
            let floorIs4Or5 = ["4F", "5F"].contains(fromNode.floor) && fromNode.floor == toNode.floor
            let bothSBlocks = sBlocks.contains(fromNode.block) && sBlocks.contains(toNode.block)
            let crossBlock = fromNode.block != toNode.block
            let bothRooms = fromNode.type == "room" && toNode.type == "room"

            if fromNode.building == "S" && fromNode.building == toNode.building
                && sameFloor && floorIs4Or5 && bothSBlocks && crossBlock && bothRooms {
                errors.append("4F/5F cannot have cross-block room-to-room edge in S building: \(edge.from) -> \(edge.to)")
            }
        }

        return ValidationResult(ok: errors.isEmpty, errors: errors)
    }
}
