import Testing
@testable import uni_navi_ios

struct GraphBuilderTests {
    @Test func graphLoadsAllNodes() {
        let graph = GraphBuilder.createGraph()
        #expect(graph.nodesById.count > 500)
        #expect(graph.edges.count > 600)
    }

    @Test func landmarkNodesExcludeJunctions() {
        let graph = GraphBuilder.createGraph()
        let landmarks = GraphBuilder.getLandmarkNodes(from: graph.nodesById)
        #expect(landmarks.count > 0)
        #expect(!landmarks.contains(where: { $0.type == "junction" }))
    }

    @Test func edgeKeyIsSymmetric() {
        let k1 = GraphBuilder.edgeKey("A", "B")
        let k2 = GraphBuilder.edgeKey("B", "A")
        #expect(k1 == k2)
    }
}

struct DijkstraTests {
    let graph = GraphBuilder.createGraph()

    @Test func sameFloorRoute() {
        // Two rooms on 1F — should find a flat-only path
        let result = DijkstraRouter.shortestPathFlatOnly(graph: graph, startId: "S_1F_SA169", endId: "S_1F_SA163")
        #expect(!result.path.isEmpty)
        #expect(result.distance < .infinity)
        #expect(result.path.first == "S_1F_SA169")
        #expect(result.path.last == "S_1F_SA163")
    }

    @Test func crossFloorComfortPreference() {
        // Cross-floor: comfort should prefer elevator
        let comfort = DijkstraRouter.findPreferredRoute(graph: graph, startId: "S_1F_SA169", endId: "S_3F_SA301", mode: .comfort)
        let fast = DijkstraRouter.findPreferredRoute(graph: graph, startId: "S_1F_SA169", endId: "S_3F_SA301", mode: .fast)

        #expect(!comfort.path.isEmpty)
        #expect(!fast.path.isEmpty)

        // Comfort should use elevator nodes
        let comfortUsesElevator = comfort.path.contains(where: { graph.nodesById[$0]?.type == "elevator" })
        #expect(comfortUsesElevator)
    }

    @Test func invalidNodeReturnsEmpty() {
        let result = DijkstraRouter.shortestPath(graph: graph, startId: "NONEXISTENT", endId: "S_1F_SA169")
        #expect(result.path.isEmpty)
        #expect(result.distance == .infinity)
    }

    @Test func shaftIdentification() {
        let elevatorShafts = DijkstraRouter.identifyShafts(graph: graph, transportType: "elevator")
        let staircaseShafts = DijkstraRouter.identifyShafts(graph: graph, transportType: "staircase")
        #expect(!elevatorShafts.isEmpty)
        #expect(!staircaseShafts.isEmpty)
    }
}

struct RoutePresentationTests {
    let graph = GraphBuilder.createGraph()

    @Test func stepsContainStartAndArrive() {
        let result = DijkstraRouter.shortestPathFlatOnly(graph: graph, startId: "S_1F_SA169", endId: "S_1F_SA163")
        let presentation = RoutePresenter.buildRoutePresentation(pathNodeIds: result.path, graph: graph)
        #expect(!presentation.steps.isEmpty)
        #expect(presentation.steps.first?.starts(with: "Start from") == true)
        #expect(presentation.steps.last?.starts(with: "Arrive at") == true)
    }

    @Test func crossFloorHasMultipleSegments() {
        let result = DijkstraRouter.findPreferredRoute(graph: graph, startId: "S_1F_SA169", endId: "S_3F_SA301", mode: .comfort)
        let presentation = RoutePresenter.buildRoutePresentation(pathNodeIds: result.path, graph: graph)
        #expect(presentation.segments.count >= 2)
        #expect(!presentation.transitions.isEmpty)
    }

    @Test func emptyPathReturnsEmptyPresentation() {
        let presentation = RoutePresenter.buildRoutePresentation(pathNodeIds: [], graph: graph)
        #expect(presentation.segments.isEmpty)
        #expect(presentation.steps.isEmpty)
    }
}

struct GraphValidatorTests {
    @Test func realDataPasses() {
        let graph = GraphBuilder.createGraph()
        let result = GraphValidator.validate(nodes: Array(graph.nodesById.values), edges: graph.edges)
        #expect(result.ok)
    }
}
