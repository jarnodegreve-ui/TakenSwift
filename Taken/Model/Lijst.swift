import Foundation
import SwiftData

/// Een eigen lijst van taken. De Inbox is geen lijst: een taak zonder lijst zit in de Inbox.
@Model
final class Lijst {
    var naam: String
    var kleurRaw: Int
    var icoon: String
    var volgorde: Int
    var aangemaaktOp: Date

    @Relationship(deleteRule: .cascade, inverse: \Taak.lijst)
    var taken: [Taak] = []

    init(naam: String, kleur: Kleur = .blauw, icoon: String = "list.bullet", volgorde: Int = 0) {
        self.naam = naam
        self.kleurRaw = kleur.rawValue
        self.icoon = icoon
        self.volgorde = volgorde
        self.aangemaaktOp = .now
    }
}

extension Lijst {
    var kleur: Kleur {
        get { Kleur(rawValue: kleurRaw) ?? .blauw }
        set { kleurRaw = newValue.rawValue }
    }

    var aantalOpen: Int {
        taken.filter { !$0.afgewerkt }.count
    }
}
