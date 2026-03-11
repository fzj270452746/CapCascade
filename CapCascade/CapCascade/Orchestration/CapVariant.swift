import Foundation
import SpriteKit

// MARK: - Hat Type Enumeration

enum CapVariant: String, CaseIterable, Codable {
    case bangqiu  = "hat_bangqiu"
    case chef     = "hat_chef"
    case jkoer    = "hat_jkoer"
    case king     = "hat_king"
    case magic    = "hat_magic"
    case niuzai   = "hat_niuzai"

    var texturePlacard: SKTexture {
        return SKTexture(imageNamed: self.rawValue)
    }

    static var quintetPool: [CapVariant] {
        return [.chef, .jkoer, .king, .magic, .niuzai]
    }

    static func stochasticPick() -> CapVariant {
        return allCases.randomElement() ?? .chef
    }

    static func stochasticPickFromQuintet() -> CapVariant {
        return quintetPool.randomElement() ?? .chef
    }
}
