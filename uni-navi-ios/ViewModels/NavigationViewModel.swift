import Foundation
import Combine

final class NavigationViewModel: ObservableObject {
    // Search
    @Published var startQuery = ""
    @Published var startSuggestions: [Node] = []
    @Published var selectedStartId = ""
    @Published var destinationQuery = ""
    @Published var destinationSuggestions: [Node] = []
    @Published var selectedDestinationId = ""

    // Route state
    @Published var statusText = "Select a start point and a destination to begin navigation"
    @Published var steps: [String] = []
    @Published var segments: [RouteSegment] = []
    @Published var transitions: [RouteTransition] = []

    // Map state
    @Published var activeBuilding = "S"
    @Published var activeFloor = "1F"
    @Published var availableBuildings = ["S"]
    @Published var availableFloors = MapConstants.floorOrder

    // Route types
    @Published var comfortRoute: ComputedRoute?
    @Published var fastRoute: ComputedRoute?
    @Published var selectedRouteType: RouteMode = .comfort
    @Published var hasMultipleRoutes = false

    // Directions
    @Published var directionsExpanded = false

    // Current floor route overlay data
    @Published var currentFloorPoints: [MapPoint] = []

    // Internal
    private(set) var graph: NavigationGraph!
    private(set) var landmarkNodes: [Node] = []

    // MARK: - Init

    func loadGraph() {
        graph = GraphBuilder.createGraph()
        landmarkNodes = GraphBuilder.getLandmarkNodes(from: graph.nodesById)

        let validation = GraphValidator.validate(
            nodes: Array(graph.nodesById.values),
            edges: graph.edges
        )
        if !validation.ok {
            print("[UniNavi] data validation errors: \(validation.errors)")
        }
    }

    // MARK: - Search

    func updateStartQuery(_ query: String) {
        startQuery = query
        selectedStartId = ""
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        startSuggestions = q.isEmpty ? [] : landmarkNodes.filter {
            $0.label.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }.prefix(8).map { $0 }
    }

    func selectStart(_ nodeId: String) {
        guard let node = graph.nodesById[nodeId] else { return }
        selectedStartId = nodeId
        startQuery = node.label
        startSuggestions = []
    }

    func updateDestinationQuery(_ query: String) {
        destinationQuery = query
        selectedDestinationId = ""
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        destinationSuggestions = q.isEmpty ? [] : landmarkNodes.filter {
            $0.label.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }.prefix(8).map { $0 }
    }

    func selectDestination(_ nodeId: String) {
        guard let node = graph.nodesById[nodeId] else { return }
        selectedDestinationId = nodeId
        destinationQuery = node.label
        destinationSuggestions = []
    }

    // MARK: - Resolve node IDs

    private func resolveStartNodeId() -> String? {
        if !selectedStartId.isEmpty, graph.nodesById[selectedStartId] != nil {
            return selectedStartId
        }
        let q = startQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return nil }

        if let exact = landmarkNodes.first(where: {
            $0.id.lowercased() == q || $0.label.lowercased() == q
        }) { return exact.id }

        return landmarkNodes.first(where: {
            $0.id.lowercased().contains(q) || $0.label.lowercased().contains(q)
        })?.id
    }

    private func resolveDestinationId() -> String? {
        if !selectedDestinationId.isEmpty, graph.nodesById[selectedDestinationId] != nil {
            return selectedDestinationId
        }
        let q = destinationQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return nil }

        if let exact = landmarkNodes.first(where: {
            $0.id.lowercased() == q || $0.label.lowercased() == q
        }) { return exact.id }

        return landmarkNodes.first(where: {
            $0.id.lowercased().contains(q) || $0.label.lowercased().contains(q)
        })?.id
    }

    // MARK: - Search route

    func searchRoute() -> Bool {
        guard let startId = resolveStartNodeId(),
              let startNode = graph.nodesById[startId],
              let destId = resolveDestinationId(),
              let destNode = graph.nodesById[destId] else {
            return false
        }

        let sameFloor = startNode.floor == destNode.floor
        let comfortResult: PathResult
        let fastResult: PathResult

        if sameFloor {
            let result = DijkstraRouter.shortestPathFlatOnly(graph: graph, startId: startId, endId: destId)
            comfortResult = result
            fastResult = result
        } else {
            comfortResult = DijkstraRouter.findPreferredRoute(graph: graph, startId: startId, endId: destId, mode: .comfort)
            fastResult = DijkstraRouter.findPreferredRoute(graph: graph, startId: startId, endId: destId, mode: .fast)
        }

        guard !comfortResult.path.isEmpty || !fastResult.path.isEmpty else {
            statusText = "No route found"
            return false
        }

        let comfortPres = comfortResult.path.isEmpty ? nil :
            RoutePresenter.buildRoutePresentation(pathNodeIds: comfortResult.path, graph: graph)
        let fastPres = fastResult.path.isEmpty ? nil :
            RoutePresenter.buildRoutePresentation(pathNodeIds: fastResult.path, graph: graph)

        comfortRoute = comfortPres.map {
            ComputedRoute(segments: $0.segments, steps: $0.steps,
                          transitions: $0.transitions, distance: comfortResult.distance)
        }
        fastRoute = fastPres.map {
            ComputedRoute(segments: $0.segments, steps: $0.steps,
                          transitions: $0.transitions, distance: fastResult.distance)
        }

        hasMultipleRoutes = comfortRoute != nil && fastRoute != nil
        selectedRouteType = comfortRoute != nil ? .comfort : .fast

        applyActiveRoute()
        selectedDestinationId = destId
        destinationSuggestions = []
        directionsExpanded = true
        return true
    }

    // MARK: - Route switching

    func selectRouteType(_ mode: RouteMode) {
        guard mode != selectedRouteType else { return }
        let route = mode == .fast ? fastRoute : comfortRoute
        guard route != nil else { return }
        selectedRouteType = mode
        applyActiveRoute()
    }

    private func applyActiveRoute() {
        let route = selectedRouteType == .fast ? fastRoute : comfortRoute
        guard let route else { return }

        steps = route.steps
        segments = route.segments
        transitions = route.transitions
        statusText = "Route: \(route.steps.count) steps"

        if let first = route.segments.first {
            activeBuilding = first.building
            activeFloor = first.floor
            availableBuildings = Array(Set(route.segments.map(\.building)))
            availableFloors = refreshFloorOptions(building: first.building, segments: route.segments)
        }

        updateFloorOverlay()
    }

    // MARK: - Floor/building switching

    func switchFloor(_ floor: String) {
        guard segments.contains(where: { $0.building == activeBuilding && $0.floor == floor }) else { return }
        activeFloor = floor
        updateFloorOverlay()
    }

    func switchBuilding(_ building: String) {
        guard let first = segments.first(where: { $0.building == building }) else { return }
        activeBuilding = building
        activeFloor = first.floor
        availableFloors = refreshFloorOptions(building: building, segments: segments)
        updateFloorOverlay()
    }

    private func refreshFloorOptions(building: String, segments: [RouteSegment]) -> [String] {
        let floorOrder = MapConstants.floorOrder
        let floors = Set(segments.filter { $0.building == building }.map(\.floor))
        return floorOrder.filter { floors.contains($0) }
    }

    // MARK: - Route overlay for current floor

    func updateFloorOverlay() {
        guard let segment = segments.first(where: {
            $0.building == activeBuilding && $0.floor == activeFloor
        }) else {
            currentFloorPoints = []
            return
        }
        currentFloorPoints = segment.points
    }

    func mapAssetName() -> String? {
        MapConstants.mapAssetName(building: activeBuilding, floor: activeFloor)
    }
}
