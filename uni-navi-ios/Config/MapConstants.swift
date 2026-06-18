import Foundation

enum MapConstants {
    static let floorOrder = ["0F", "1F", "2F", "3F", "4F", "5F"]

    struct ViewBox {
        let width: Double
        let height: Double
    }

    struct Offset {
        let x: Double
        let y: Double
    }

    static let viewBoxes: [String: [String: ViewBox]] = [
        "S": [
            "0F": ViewBox(width: 760, height: 720),
            "1F": ViewBox(width: 560, height: 680),
            "2F": ViewBox(width: 520, height: 690),
            "3F": ViewBox(width: 522, height: 681),
            "4F": ViewBox(width: 522, height: 681),
            "5F": ViewBox(width: 521, height: 681),
        ]
    ]

    static let modelOffsets: [String: [String: Offset]] = [
        "S": [
            "0F": Offset(x: 81, y: 120),
            "1F": Offset(x: 140, y: 120),
            "2F": Offset(x: 160, y: 120),
            "3F": Offset(x: 160, y: 120),
            "4F": Offset(x: 160, y: 120),
            "5F": Offset(x: 160, y: 120),
        ]
    ]

    static let mapAssets: [String: [String: String]] = [
        "S": [
            "0F": "S_0F",
            "1F": "S_1F",
            "2F": "S_2F",
            "3F": "S_3F",
            "4F": "S_4F",
            "5F": "S_5F",
        ]
    ]

    static func viewBox(building: String, floor: String) -> ViewBox {
        viewBoxes[building]?[floor] ?? ViewBox(width: 800, height: 500)
    }

    static func modelOffset(building: String, floor: String) -> Offset {
        modelOffsets[building]?[floor] ?? Offset(x: 0, y: 0)
    }

    static func mapAssetName(building: String, floor: String) -> String? {
        mapAssets[building]?[floor]
    }
}
