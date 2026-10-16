# Taken

Een takenapp voor iPhone, in de geest van TickTick. SwiftUI en SwiftData, alles lokaal op het toestel.

## Wat erin zit

- Slimme lijsten: Vandaag (met verlopen taken), Komende 7 dagen, Inbox, Alles, Afgewerkt.
- Eigen lijsten met kleur en icoon, en tags.
- Taken met notities, datum, tijdstip, prioriteit (geen, laag, gemiddeld, hoog), subtaken en tags.
- Herinneringen als lokale meldingen, ook als de app dicht is.
- Kalender met maand- en weekweergave.
- Zoeken in titels en notities.
- Snel toevoegen met de plusknop; vegen om af te werken, te verzetten of te wissen.

## Openen en draaien

1. Open `Taken.xcodeproj` in Xcode 16 of nieuwer.
2. Kies het doel `Taken`, ga naar *Signing & Capabilities* en kies je eigen team (een gratis Apple ID volstaat om op je eigen iPhone te installeren).
3. Pas eventueel de bundle-id aan (`be.jarnodegreve.taken`).
4. Sluit je iPhone aan, kies hem als bestemming en druk op Run. De eerste keer moet je op de iPhone onder *Instellingen > Algemeen > VPN en apparaatbeheer* je ontwikkelaarsprofiel vertrouwen.

Met een gratis Apple ID blijft de app zeven dagen geldig; daarna opnieuw installeren vanuit Xcode. Met een betaald ontwikkelaarsaccount kan de app via TestFlight of de App Store.

## Opbouw

- `Taken/Model/`: SwiftData-modellen (`Lijst`, `Taak`, `Subtaak`, `Tag`).
- `Taken/Logica/`: datumrekenwerk, herinneringen, slimme lijsten, voorbeelddata.
- `Taken/Weergaven/`: de schermen per tabblad.

Zie `CLAUDE.md` voor de afspraken in de code.
