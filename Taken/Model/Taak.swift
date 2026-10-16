import Foundation
import SwiftData

/// Een taak. Heet bewust niet `Task`, om niet te botsen met Swift-concurrency.
@Model
final class Taak {
    /// Vast kenmerk, ook gebruikt als kenmerk van de melding.
    var uuid: UUID
    var titel: String
    var notities: String
    var afgewerkt: Bool
    var afgewerktOp: Date?
    /// Zonder tijd staat de vervaldatum op middernacht en is `heeftTijd` vals.
    var vervaldatum: Date?
    var heeftTijd: Bool
    var herinnering: Date?
    var prioriteitRaw: Int
    var volgorde: Int
    var aangemaaktOp: Date
    var lijst: Lijst?

    @Relationship(deleteRule: .cascade, inverse: \Subtaak.taak)
    var subtaken: [Subtaak] = []

    @Relationship(inverse: \Tag.taken)
    var tags: [Tag] = []

    init(
        titel: String,
        notities: String = "",
        vervaldatum: Date? = nil,
        heeftTijd: Bool = false,
        herinnering: Date? = nil,
        prioriteit: Prioriteit = .geen,
        volgorde: Int = 0
    ) {
        self.uuid = UUID()
        self.titel = titel
        self.notities = notities
        self.afgewerkt = false
        self.afgewerktOp = nil
        self.vervaldatum = vervaldatum
        self.heeftTijd = heeftTijd
        self.herinnering = herinnering
        self.prioriteitRaw = prioriteit.rawValue
        self.volgorde = volgorde
        self.aangemaaktOp = .now
    }
}

extension Taak {
    var prioriteit: Prioriteit {
        get { Prioriteit(rawValue: prioriteitRaw) ?? .geen }
        set { prioriteitRaw = newValue.rawValue }
    }

    var gesorteerdeSubtaken: [Subtaak] {
        subtaken.sorted { a, b in
            if a.volgorde != b.volgorde { return a.volgorde < b.volgorde }
            return a.titel < b.titel
        }
    }

    var gesorteerdeTags: [Tag] {
        tags.sorted { $0.naam.localizedCaseInsensitiveCompare($1.naam) == .orderedAscending }
    }

    var aantalSubtakenAfgewerkt: Int {
        subtaken.filter { $0.afgewerkt }.count
    }

    /// Te laat: de dag is voorbij, of het tijdstip is voorbij als er een tijd op staat.
    var verlopen: Bool {
        guard !afgewerkt, let datum = vervaldatum else { return false }
        if heeftTijd { return datum < .now }
        return Datums.startVanDag(datum) < Datums.startVanDag(.now)
    }

    /// Of de vervaldatum op de gegeven dag valt.
    func valtOp(_ dag: Date) -> Bool {
        guard let datum = vervaldatum else { return false }
        return Datums.zelfdeDag(datum, dag)
    }

    func markeer(afgewerkt nieuw: Bool) {
        afgewerkt = nieuw
        afgewerktOp = nieuw ? .now : nil
        Herinneringen.plan(voor: self)
    }

    /// Zet de taak op een andere dag (of haalt de datum weg). Een tijdstip blijft staan,
    /// en een herinnering die op de oude dag stond, verhuist mee.
    func zetDatum(_ dag: Date?) {
        guard let dag else {
            vervaldatum = nil
            heeftTijd = false
            return
        }
        let oud = vervaldatum
        let nieuw = heeftTijd ? Datums.combineer(dag: dag, tijd: oud ?? dag) : Datums.startVanDag(dag)
        if let moment = herinnering, let oudeDatum = oud, Datums.zelfdeDag(moment, oudeDatum) {
            herinnering = Datums.combineer(dag: nieuw, tijd: moment)
        }
        vervaldatum = nieuw
    }

    /// Zet een tijdstip op de vervaldatum, of haalt het weg.
    func zetTijd(_ aan: Bool) {
        guard let datum = vervaldatum else {
            heeftTijd = false
            return
        }
        heeftTijd = aan
        vervaldatum = aan ? Datums.metTijd(datum, uur: 9, minuut: 0) : Datums.startVanDag(datum)
    }
}
