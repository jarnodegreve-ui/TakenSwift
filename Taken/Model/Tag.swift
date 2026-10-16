import Foundation
import SwiftData

/// Een tag die op meerdere taken kan staan.
@Model
final class Tag {
    var naam: String
    var kleurRaw: Int
    var taken: [Taak] = []

    init(naam: String, kleur: Kleur = .grijs) {
        self.naam = naam
        self.kleurRaw = kleur.rawValue
    }
}

extension Tag {
    var kleur: Kleur {
        get { Kleur(rawValue: kleurRaw) ?? .grijs }
        set { kleurRaw = newValue.rawValue }
    }

    var aantalOpen: Int {
        taken.filter { !$0.afgewerkt }.count
    }
}
