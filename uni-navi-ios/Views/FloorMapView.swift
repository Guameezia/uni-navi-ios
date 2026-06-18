import SwiftUI
import WebKit

struct FloorMapView: View {
    @ObservedObject var vm: NavigationViewModel

    var body: some View {
        GeometryReader { geo in
            let vb = MapConstants.viewBox(building: vm.activeBuilding, floor: vm.activeFloor)
            let containerSize = geo.size
            let aspect = vb.width / vb.height
            let fitWidth = min(containerSize.width, containerSize.height * aspect)
            let fitHeight = fitWidth / aspect

            ZStack {
                SVGWebView(
                    building: vm.activeBuilding,
                    floor: vm.activeFloor
                )

                RouteOverlayCanvas(
                    points: vm.currentFloorPoints,
                    building: vm.activeBuilding,
                    floor: vm.activeFloor,
                    viewSize: CGSize(width: fitWidth, height: fitHeight)
                )
                .allowsHitTesting(false)
            }
            .frame(width: fitWidth, height: fitHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - SVG WebView

struct SVGWebView: UIViewRepresentable {
    let building: String
    let floor: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        loadSVG(in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let key = "\(building)_\(floor)"
        if context.coordinator.currentKey != key {
            context.coordinator.currentKey = key
            loadSVG(in: webView)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var currentKey = ""
    }

    private func loadSVG(in webView: WKWebView) {
        guard let name = MapConstants.mapAssetName(building: building, floor: floor),
              let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Resources/Maps")
                ?? Bundle.main.url(forResource: name, withExtension: "svg") else {
            webView.loadHTMLString("<html><body style='background:transparent'></body></html>", baseURL: nil)
            return
        }

        do {
            let svgContent = try String(contentsOf: url, encoding: .utf8)
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
            <style>
              * { margin: 0; padding: 0; }
              html, body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
              svg { width: 100%; height: 100%; display: block; }
            </style>
            </head>
            <body>\(svgContent)</body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
        } catch {
            print("[UniNavi] Failed to load SVG: \(error)")
        }
    }
}

// MARK: - Route overlay drawn with SwiftUI Canvas

struct RouteOverlayCanvas: View {
    let points: [MapPoint]
    let building: String
    let floor: String
    let viewSize: CGSize

    var body: some View {
        Canvas { context, size in
            let canvasPoints = transformedPoints(in: size)
            guard canvasPoints.count >= 2 else { return }

            let ortho = orthogonalize(canvasPoints)

            var path = Path()
            path.move(to: CGPoint(x: ortho[0].x, y: ortho[0].y))

            for i in 1..<ortho.count {
                let prev = ortho[i - 1]
                let current = ortho[i]
                let next: MapPoint? = i + 1 < ortho.count ? ortho[i + 1] : nil

                guard let next else {
                    path.addLine(to: CGPoint(x: current.x, y: current.y))
                    continue
                }

                let inDx = current.x - prev.x
                let inDy = current.y - prev.y
                let outDx = next.x - current.x
                let outDy = next.y - current.y
                let inLen = sqrt(inDx * inDx + inDy * inDy)
                let outLen = sqrt(outDx * outDx + outDy * outDy)
                let isStraight = (inDx == 0 && outDx == 0) || (inDy == 0 && outDy == 0)

                if isStraight || inLen < 2 || outLen < 2 {
                    path.addLine(to: CGPoint(x: current.x, y: current.y))
                    continue
                }

                let radius = min(10, inLen / 2, outLen / 2)
                let start = CGPoint(
                    x: current.x - (inDx / inLen) * radius,
                    y: current.y - (inDy / inLen) * radius
                )
                let end = CGPoint(
                    x: current.x + (outDx / outLen) * radius,
                    y: current.y + (outDy / outLen) * radius
                )
                path.addLine(to: start)
                path.addQuadCurve(to: end, control: CGPoint(x: current.x, y: current.y))
            }

            context.stroke(path, with: .color(.green), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

            // Start marker
            let startPt = ortho[0]
            context.fill(
                Path(ellipseIn: CGRect(x: startPt.x - 5, y: startPt.y - 5, width: 10, height: 10)),
                with: .color(Color(red: 0.086, green: 0.639, blue: 0.165))
            )

            // End marker
            let endPt = ortho[ortho.count - 1]
            context.fill(
                Path(ellipseIn: CGRect(x: endPt.x - 5, y: endPt.y - 5, width: 10, height: 10)),
                with: .color(Color(red: 0.114, green: 0.306, blue: 0.847))
            )
        }
        .frame(width: viewSize.width, height: viewSize.height)
    }

    private func transformedPoints(in size: CGSize) -> [MapPoint] {
        let vb = MapConstants.viewBox(building: building, floor: floor)
        let offset = MapConstants.modelOffset(building: building, floor: floor)
        let scaleX = size.width / vb.width
        let scaleY = size.height / vb.height

        return points.map { p in
            MapPoint(
                x: (p.x - offset.x) * scaleX,
                y: (p.y - offset.y) * scaleY,
                id: p.id
            )
        }
    }

    private func orthogonalize(_ points: [MapPoint]) -> [MapPoint] {
        guard points.count >= 2 else { return points }
        var result = [points[0]]
        for i in 1..<points.count {
            let prev = result.last!
            let next = points[i]
            if prev.x != next.x && prev.y != next.y {
                result.append(MapPoint(x: next.x, y: prev.y))
            }
            result.append(next)
        }
        return result
    }
}
