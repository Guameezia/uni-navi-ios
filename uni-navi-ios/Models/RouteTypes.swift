import Foundation

struct PathResult {
    let path: [String]
    let distance: Double
    var routeKind: String?
}

extension PathResult {
    static let empty = PathResult(path: [], distance: .infinity)
}

struct RouteSegment: Identifiable {
    let id: String
    let building: String
    let floor: String
    let nodeIds: [String]
    let points: [MapPoint]
}

struct MapPoint: Equatable {
    let x: Double
    let y: Double
    var id: String = ""
}

struct RouteTransition {
    let type: String // "building" or "floor"
    let edgeType: String
    let fromNodeId: String
    let toNodeId: String
    let fromBuilding: String
    let toBuilding: String
    let fromFloor: String
    let toFloor: String
    let label: String
}

struct RoutePresentation {
    let segments: [RouteSegment]
    let transitions: [RouteTransition]
    let steps: [String]
}

extension RoutePresentation {
    static let empty = RoutePresentation(segments: [], transitions: [], steps: [])
}

struct ComputedRoute {
    let segments: [RouteSegment]
    let steps: [String]
    let transitions: [RouteTransition]
    let distance: Double
}

enum RouteMode: String, CaseIterable {
    case comfort
    case fast
}
