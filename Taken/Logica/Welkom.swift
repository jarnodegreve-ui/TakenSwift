import Foundation
import SwiftData

/// Voorbeeldtaken bij de eerste start, zodat het scherm niet leeg is.
enum Welkom {
    static func maakVoorbeeldtaken(in context: ModelContext) {
        let vandaag = Datums.startVanDag(.now)

        let eerste = Taak(
            titel: "Welkom bij Taken",
            notities: "Tik op een taak om ze te openen. Veeg naar rechts om ze af te werken, naar links om ze te verzetten of te wissen.",
            vervaldatum: vandaag,
            volgorde: 0
        )
        context.insert(eerste)

        let stappen = [
            "Voeg een taak toe met de plusknop",
            "Maak een lijst aan onder Lijsten",
            "Zet een herinnering op een taak",
        ]
        for (index, stap) in stappen.enumerated() {
            let subtaak = Subtaak(titel: stap, volgorde: index)
            context.insert(subtaak)
            subtaak.taak = eerste
        }

        let tweede = Taak(
            titel: "Bekijk de kalender",
            notities: "Maand- en weekweergave, met een stip per dag met taken.",
            vervaldatum: Datums.plusDagen(1, vanaf: vandaag),
            prioriteit: .laag,
            volgorde: 1
        )
        context.insert(tweede)

        try? context.save()
    }
}
