# Taken

Takenapp voor iPhone, in de geest van TickTick: lijsten, taken met subtaken, datums, prioriteit, tags, herinneringen en een kalender. Eigen project van Jarno, los van Crewline, het VHB-portaal en FleetCore.

## Stack

- SwiftUI, SwiftData, UserNotifications. iOS 17 of hoger, alleen iPhone.
- Alles staat lokaal op het toestel (SwiftData, dus SQLite). Geen account, geen server, geen sync.
- Xcode-project met een gesynchroniseerde map (`Taken/`): elk bestand dat je daar neerzet, hoort automatisch bij het doel. Projectbestand is `Taken.xcodeproj`, schema `Taken`.
- CI bouwt op een macOS-runner voor de simulator (`.github/workflows/ci.yml`).

## Opbouw

- `Taken/Model/`: SwiftData-modellen `Lijst`, `Taak`, `Subtaak`, `Tag`, plus `Prioriteit` en `Kleur`. Enums worden als ruwe `Int` bewaard (`prioriteitRaw`, `kleurRaw`), met een berekende eigenschap erbovenop.
- `Taken/Logica/`: `Datums` (zuiver Foundation, Nederlandse kalender, week begint op maandag), `Herinneringen` (lokale meldingen), `Weergave` (de slimme lijsten), `Welkom` (voorbeeldtaken bij de eerste start), `Voorbeeld` (geheugencontainer voor previews).
- `Taken/Weergaven/`: tabbladen Vandaag, Lijsten, Kalender, Zoeken. `TakenLijstView` toont elke `Weergave`; `TaakDetailView` bewerkt een taak; `NieuweTaakView` is het snel-toevoegen-blad.

## Regels

- Inbox is geen aparte lijst: een taak zonder `lijst` zit in de Inbox.
- Een taak zonder tijd heeft `vervaldatum` op middernacht en `heeftTijd = false`.
- Herinneringen worden altijd via `Herinneringen.plan(voor:)` herpland; het kenmerk van de melding is `taak.uuid`.
- Geen `#Predicate` met datums: alles wordt opgehaald met `@Query` en in Swift gefilterd. Dat is bewust, de datasets zijn klein.
- Geen `Task` als typenaam: het model heet `Taak` om botsing met Swift-concurrency te vermijden.
- UI-tekst in het Nederlands, zonder em dash: komma of nieuwe zin.
- Nooit echte taken of namen in voorbeelddata of tests.
