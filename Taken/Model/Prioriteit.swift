import SwiftUI

/// Prioriteit van een taak. De ruwe waarden volgen de gewoonte van TickTick (0, 1, 3, 5),
/// zodat sorteren op prioriteit gewoon op het getal kan.
enum Prioriteit: Int, CaseIterable, Identifiable, Codable {
    case geen = 0
    case laag = 1
    case gemiddeld = 3
    case hoog = 5

    var id: Int { rawValue }

    var naam: String {
        switch self {
        case .geen: "Geen"
        case .laag: "Laag"
        case .gemiddeld: "Gemiddeld"
        case .hoog: "Hoog"
        }
    }

    var kleur: Color {
        switch self {
        case .geen: .secondary
        case .laag: Kleur.blauw.kleur
        case .gemiddeld: Kleur.oranje.kleur
        case .hoog: Kleur.rood.kleur
        }
    }

    var symbool: String {
        self == .geen ? "flag" : "flag.fill"
    }
}
