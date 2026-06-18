import Foundation

struct Edge: Codable, Equatable {
    let from: String
    let to: String
    let distance: Double
    let directionHint: String?
    let edgeType: String
}
