import SwiftData
import SwiftUI

/// Toont de taken van een weergave: een slimme lijst, een eigen lijst of een tag.
struct TakenLijstView: View {
    let weergave: Weergave

    @Environment(\.modelContext) private var context
    @Query(sort: \Taak.volgorde) private var alleTaken: [Taak]
    @Query(sort: \Lijst.volgorde) private var lijsten: [Lijst]
    @State private var toonNieuw = false
    @State private var toonAfgewerkt = false
    @State private var toonLijstBewerken = false
    @State private var toonTagBewerken = false

    private struct Sectie: Identifiable {
        let id: String
        let titel: String?
        let verlopen: Bool
        let taken: [Taak]
    }

    var body: some View {
        List {
            ForEach(secties) { sectie in
                Section {
                    ForEach(sectie.taken) { taak in
                        rij(taak)
                    }
                } header: {
                    if let titel = sectie.titel {
                        Text(titel)
                            .foregroundStyle(sectie.verlopen ? Color.red : Color.secondary)
                    }
                }
            }
            if weergave != .afgewerkt && !afgewerkteTaken.isEmpty {
                Section {
                    if toonAfgewerkt {
                        ForEach(afgewerkteTaken) { taak in
                            rij(taak)
                        }
                    }
                } header: {
                    Button {
                        withAnimation { toonAfgewerkt.toggle() }
                    } label: {
                        HStack {
                            Text("Afgewerkt (\(afgewerkteTaken.count))")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .rotationEffect(.degrees(toonAfgewerkt ? 90 : 0))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 88, for: .scrollContent)
        .overlay {
            if secties.isEmpty && afgewerkteTaken.isEmpty {
                ContentUnavailableView {
                    Label(legeTitel, systemImage: "checkmark.circle")
                } description: {
                    Text(legeTekst)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if weergave != .afgewerkt {
                plusKnop
            }
        }
        .navigationTitle(weergave.titel)
        .navigationDestination(for: Taak.self) { taak in
            TaakDetailView(taak: taak)
        }
        .toolbar {
            if weergave != .afgewerkt {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if weergave.isLijst {
                            Button("Lijst bewerken", systemImage: "pencil") {
                                toonLijstBewerken = true
                            }
                        }
                        if weergave.isTag {
                            Button("Tag bewerken", systemImage: "pencil") {
                                toonTagBewerken = true
                            }
                        }
                        Toggle("Afgewerkte tonen", systemImage: "checkmark.circle", isOn: $toonAfgewerkt)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $toonNieuw) {
            NieuweTaakView(lijst: weergave.lijst, datum: weergave.standaardDatum, tag: weergave.tag)
        }
        .sheet(isPresented: $toonLijstBewerken) {
            if let lijst = weergave.lijst {
                LijstBewerkView(lijst: lijst)
            }
        }
        .sheet(isPresented: $toonTagBewerken) {
            if let tag = weergave.tag {
                TagBewerkView(tag: tag)
            }
        }
    }

    // MARK: Rijen

    private func rij(_ taak: Taak) -> some View {
        NavigationLink(value: taak) {
            TaakRij(taak: taak, toonLijst: toontLijstnaam)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                withAnimation { taak.markeer(afgewerkt: !taak.afgewerkt) }
            } label: {
                Label(
                    taak.afgewerkt ? "Heropenen" : "Afwerken",
                    systemImage: taak.afgewerkt ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                wis(taak)
            } label: {
                Label("Wissen", systemImage: "trash")
            }
            if !taak.afgewerkt {
                Button {
                    verzet(taak, naar: Datums.plusDagen(1, vanaf: vandaag))
                } label: {
                    Label("Morgen", systemImage: "arrow.forward")
                }
                .tint(.orange)
            }
        }
        .contextMenu {
            menuItems(voor: taak)
        }
    }

    @ViewBuilder
    private func menuItems(voor taak: Taak) -> some View {
        Button {
            withAnimation { taak.markeer(afgewerkt: !taak.afgewerkt) }
        } label: {
            Label(
                taak.afgewerkt ? "Heropenen" : "Afwerken",
                systemImage: taak.afgewerkt ? "arrow.uturn.backward" : "checkmark"
            )
        }
        Menu {
            Button("Vandaag") { verzet(taak, naar: vandaag) }
            Button("Morgen") { verzet(taak, naar: Datums.plusDagen(1, vanaf: vandaag)) }
            Button("Volgende week") { verzet(taak, naar: Datums.plusDagen(7, vanaf: vandaag)) }
            Button("Geen datum") { verzet(taak, naar: nil) }
        } label: {
            Label("Datum", systemImage: "calendar")
        }
        Menu {
            ForEach(Prioriteit.allCases) { prioriteit in
                Button {
                    taak.prioriteit = prioriteit
                } label: {
                    Label(prioriteit.naam, systemImage: prioriteit.symbool)
                }
            }
        } label: {
            Label("Prioriteit", systemImage: "flag")
        }
        Menu {
            Button("Inbox") { taak.lijst = nil }
            ForEach(lijsten) { lijst in
                Button(lijst.naam) { taak.lijst = lijst }
            }
        } label: {
            Label("Verplaats naar", systemImage: "folder")
        }
        Divider()
        Button(role: .destructive) {
            wis(taak)
        } label: {
            Label("Wissen", systemImage: "trash")
        }
    }

    private var plusKnop: some View {
        Button {
            toonNieuw = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
        }
        .padding(20)
        .accessibilityLabel("Nieuwe taak")
    }

    // MARK: Acties

    private func verzet(_ taak: Taak, naar dag: Date?) {
        withAnimation {
            taak.zetDatum(dag)
        }
        Herinneringen.plan(voor: taak)
    }

    private func wis(_ taak: Taak) {
        Herinneringen.annuleer(taak)
        withAnimation {
            context.delete(taak)
        }
        try? context.save()
    }

    // MARK: Gegevens

    private var vandaag: Date {
        Datums.startVanDag(.now)
    }

    private var toontLijstnaam: Bool {
        switch weergave {
        case .vandaag, .komende7, .alles, .afgewerkt, .tag: true
        case .inbox, .lijst: false
        }
    }

    private func hoortErbij(_ taak: Taak) -> Bool {
        switch weergave {
        case .vandaag:
            guard let datum = taak.vervaldatum else { return false }
            return Datums.startVanDag(datum) <= vandaag
        case .komende7:
            guard let datum = taak.vervaldatum else { return false }
            return Datums.startVanDag(datum) <= Datums.plusDagen(6, vanaf: vandaag)
        case .inbox:
            return taak.lijst == nil
        case .alles:
            return true
        case .afgewerkt:
            return false
        case .lijst(let lijst):
            return taak.lijst == lijst
        case .tag(let tag):
            return taak.tags.contains(tag)
        }
    }

    private func hoortErbijAlsAfgewerkt(_ taak: Taak) -> Bool {
        switch weergave {
        case .vandaag:
            guard let moment = taak.afgewerktOp else { return false }
            return Datums.isVandaag(moment)
        case .komende7:
            guard let datum = taak.vervaldatum else { return false }
            let dag = Datums.startVanDag(datum)
            return dag >= vandaag && dag <= Datums.plusDagen(6, vanaf: vandaag)
        case .inbox:
            return taak.lijst == nil
        case .alles, .afgewerkt:
            return true
        case .lijst(let lijst):
            return taak.lijst == lijst
        case .tag(let tag):
            return taak.tags.contains(tag)
        }
    }

    private var openTaken: [Taak] {
        alleTaken
            .filter { !$0.afgewerkt && hoortErbij($0) }
            .sorted { a, b in
                let datumA = a.vervaldatum ?? .distantFuture
                let datumB = b.vervaldatum ?? .distantFuture
                if datumA != datumB { return datumA < datumB }
                if a.prioriteitRaw != b.prioriteitRaw { return a.prioriteitRaw > b.prioriteitRaw }
                return a.volgorde < b.volgorde
            }
    }

    private var afgewerkteTaken: [Taak] {
        alleTaken
            .filter { $0.afgewerkt && hoortErbijAlsAfgewerkt($0) }
            .sorted { ($0.afgewerktOp ?? .distantPast) > ($1.afgewerktOp ?? .distantPast) }
    }

    private func isVerlopen(_ taak: Taak) -> Bool {
        guard let datum = taak.vervaldatum else { return false }
        return Datums.startVanDag(datum) < vandaag
    }

    private var secties: [Sectie] {
        let open = openTaken
        switch weergave {
        case .vandaag:
            let verlopen = open.filter { isVerlopen($0) }
            let vanVandaag = open.filter { !isVerlopen($0) }
            return [
                Sectie(id: "verlopen", titel: "Verlopen", verlopen: true, taken: verlopen),
                Sectie(id: "vandaag", titel: verlopen.isEmpty ? nil : "Vandaag", verlopen: false, taken: vanVandaag),
            ].filter { !$0.taken.isEmpty }

        case .komende7:
            var resultaat: [Sectie] = []
            let verlopen = open.filter { isVerlopen($0) }
            if !verlopen.isEmpty {
                resultaat.append(Sectie(id: "verlopen", titel: "Verlopen", verlopen: true, taken: verlopen))
            }
            for verschil in 0..<7 {
                let dag = Datums.plusDagen(verschil, vanaf: vandaag)
                let vanDag = open.filter { $0.valtOp(dag) }
                if !vanDag.isEmpty {
                    resultaat.append(Sectie(id: "dag\(verschil)", titel: Datums.dagTitel(dag), verlopen: false, taken: vanDag))
                }
            }
            return resultaat

        case .alles:
            var resultaat: [Sectie] = []
            let inbox = open.filter { $0.lijst == nil }
            if !inbox.isEmpty {
                resultaat.append(Sectie(id: "inbox", titel: "Inbox", verlopen: false, taken: inbox))
            }
            for (index, lijst) in lijsten.enumerated() {
                let vanLijst = open.filter { $0.lijst == lijst }
                if !vanLijst.isEmpty {
                    resultaat.append(Sectie(id: "lijst\(index)", titel: lijst.naam, verlopen: false, taken: vanLijst))
                }
            }
            return resultaat

        case .afgewerkt:
            let groepen = Dictionary(grouping: afgewerkteTaken) { taak in
                Datums.startVanDag(taak.afgewerktOp ?? .distantPast)
            }
            return groepen.keys.sorted(by: >).map { dag in
                Sectie(
                    id: "afgewerkt\(dag.timeIntervalSinceReferenceDate)",
                    titel: Datums.dagTitel(dag),
                    verlopen: false,
                    taken: groepen[dag] ?? []
                )
            }

        case .inbox, .lijst, .tag:
            let verlopen = open.filter { isVerlopen($0) }
            let rest = open.filter { !isVerlopen($0) }
            return [
                Sectie(id: "verlopen", titel: "Verlopen", verlopen: true, taken: verlopen),
                Sectie(id: "open", titel: nil, verlopen: false, taken: rest),
            ].filter { !$0.taken.isEmpty }
        }
    }

    private var legeTitel: String {
        switch weergave {
        case .vandaag: "Niets voor vandaag"
        case .komende7: "Niets gepland"
        case .inbox: "Inbox is leeg"
        case .alles: "Nog geen taken"
        case .afgewerkt: "Nog niets afgewerkt"
        case .lijst, .tag: "Geen taken"
        }
    }

    private var legeTekst: String {
        weergave == .afgewerkt
            ? "Afgewerkte taken komen hier terecht."
            : "Tik op de plusknop om een taak toe te voegen."
    }
}

#Preview("Vandaag") {
    NavigationStack {
        TakenLijstView(weergave: .vandaag)
    }
    .modelContainer(Voorbeeld.container)
    .environment(\.locale, Datums.taal)
}

#Preview("Komende 7 dagen") {
    NavigationStack {
        TakenLijstView(weergave: .komende7)
    }
    .modelContainer(Voorbeeld.container)
    .environment(\.locale, Datums.taal)
}
