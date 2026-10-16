import Foundation
import SwiftData

/// Geheugencontainer met anonieme voorbeelddata voor previews.
@MainActor
enum Voorbeeld {
    static let container: ModelContainer = {
        let configuratie = ModelConfiguration(isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Lijst.self, Taak.self, Subtaak.self, Tag.self,
                configurations: configuratie
            )
        } catch {
            fatalError("Voorbeeldcontainer kon niet starten: \(error)")
        }

        let context = container.mainContext
        let vandaag = Datums.startVanDag(.now)

        let werk = Lijst(naam: "Werk", kleur: .blauw, icoon: "briefcase", volgorde: 0)
        let thuis = Lijst(naam: "Thuis", kleur: .groen, icoon: "house", volgorde: 1)
        context.insert(werk)
        context.insert(thuis)

        let dringend = Tag(naam: "dringend", kleur: .rood)
        let wachten = Tag(naam: "wachten", kleur: .geel)
        context.insert(dringend)
        context.insert(wachten)

        let planning = Taak(titel: "Weekplanning nakijken", vervaldatum: vandaag, prioriteit: .hoog, volgorde: 0)
        context.insert(planning)
        planning.lijst = werk
        planning.tags.append(dringend)
        for (index, titel) in ["Rotatie controleren", "Afwezigheden invullen", "Doorsturen"].enumerated() {
            let subtaak = Subtaak(titel: titel, volgorde: index)
            context.insert(subtaak)
            subtaak.taak = planning
        }

        let vergadering = Taak(
            titel: "Overleg stelplaats",
            vervaldatum: Datums.metTijd(vandaag, uur: 14, minuut: 0),
            heeftTijd: true,
            herinnering: Datums.metTijd(vandaag, uur: 13, minuut: 30),
            prioriteit: .gemiddeld,
            volgorde: 1
        )
        context.insert(vergadering)
        vergadering.lijst = werk

        let boodschappen = Taak(titel: "Boodschappen", vervaldatum: Datums.plusDagen(1, vanaf: vandaag), volgorde: 2)
        context.insert(boodschappen)
        boodschappen.lijst = thuis

        let teLaat = Taak(titel: "Band oppompen", vervaldatum: Datums.plusDagen(-2, vanaf: vandaag), prioriteit: .laag, volgorde: 3)
        context.insert(teLaat)
        teLaat.lijst = thuis
        teLaat.tags.append(wachten)

        let zonderDatum = Taak(titel: "Boek uitlezen", volgorde: 4)
        context.insert(zonderDatum)

        let klaar = Taak(titel: "Vuilnis buitenzetten", vervaldatum: vandaag, volgorde: 5)
        context.insert(klaar)
        klaar.afgewerkt = true
        klaar.afgewerktOp = .now

        try? context.save()
        return container
    }()
}
