import Foundation

struct Node: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let label: String
    let building: String
    let floor: String
    let block: String
    let x: Double
    let y: Double

    var isLandmark: Bool {
        ["room", "staircase", "elevator", "entrance", "exit", "tunnel", "toilet", "food"].contains(type)
    }
}
