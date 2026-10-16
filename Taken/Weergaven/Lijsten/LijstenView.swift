import SwiftData
import SwiftUI

/// Het overzicht: slimme lijsten, eigen lijsten en tags.
struct LijstenView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Lijst.volgorde) private var lijsten: [Lijst]
    @Query(sort: \Tag.naam) private var tags: [Tag]
    @Query private var alleTaken: [Taak]

    @State private var toonNieuweLijst = false
    @State private var toonNieuweTag = false
    @State private var toonInstellingen = false
    @State private var teWissenLijst: Lijst?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    slimmeRij(.vandaag, aantal: aantalVandaag)
                    slimmeRij(.komende7, aantal: aantalKomende7)
                    slimmeRij(.inbox, aantal: aantalInbox)
                    slimmeRij(.alles, aantal: openTaken.count)
                    slimmeRij(.afgewerkt, aantal: 0)
                }

                Section("Lijsten") {
                    ForEach(lijsten) { lijst in
                        NavigationLink(value: Weergave.lijst(lijst)) {
                            Label {
                                Text(lijst.naam)
                            } icon: {
                                Image(systemName: lijst.icoon)
                                    .foregroundStyle(lijst.kleur.kleur)
                            }
                        }
                        .badge(lijst.aantalOpen)
                    }
                    .onDelete { posities in
                        teWissenLijst = posities.first.map { lijsten[$0] }
                    }
                    .onMove(perform: verplaatsLijsten)
                    Button("Nieuwe lijst", systemImage: "plus") {
                        toonNieuweLijst = true
                    }
                }

                Section("Tags") {
                    ForEach(tags) { tag in
                        NavigationLink(value: Weergave.tag(tag)) {
                            Label {
                                Text(tag.naam)
                            } icon: {
                                Image(systemName: "number")
                                    .foregroundStyle(tag.kleur.kleur)
                            }
                        }
                        .badge(tag.aantalOpen)
                    }
                    .onDelete(perform: wisTags)
                    Button("Nieuwe tag", systemImage: "plus") {
                        toonNieuweTag = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Lijsten")
            .navigationDestination(for: Weergave.self) { weergave in
                TakenLijstView(weergave: weergave)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toonInstellingen = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Instellingen")
                }
            }
            .sheet(isPresented: $toonNieuweLijst) {
                LijstBewerkView(lijst: nil)
            }
            .sheet(isPresented: $toonNieuweTag) {
                TagBewerkView(tag: nil)
            }
            .sheet(isPresented: $toonInstellingen) {
                InstellingenView()
            }
            .confirmationDialog(
                "Lijst wissen?",
                isPresented: wisBevestiging,
                titleVisibility: .visible,
                presenting: teWissenLijst
            ) { lijst in
                Button("Taken naar Inbox verplaatsen") {
                    wis(lijst, takenBehouden: true)
                }
                Button("Lijst en taken wissen", role: .destructive) {
                    wis(lijst, takenBehouden: false)
                }
            } message: { lijst in
                Text("\"\(lijst.naam)\" bevat \(lijst.taken.count) taken.")
            }
        }
    }

    private func slimmeRij(_ weergave: Weergave, aantal: Int) -> some View {
        NavigationLink(value: weergave) {
            Label(weergave.titel, systemImage: weergave.symbool)
        }
        .badge(aantal)
    }

    // MARK: Tellingen

    private var vandaag: Date {
        Datums.startVanDag(.now)
    }

    private var openTaken: [Taak] {
        alleTaken.filter { !$0.afgewerkt }
    }

    private var aantalVandaag: Int {
        openTaken.filter { taak in
            guard let datum = taak.vervaldatum else { return false }
            return Datums.startVanDag(datum) <= vandaag
        }.count
    }

    private var aantalKomende7: Int {
        let grens = Datums.plusDagen(6, vanaf: vandaag)
        return openTaken.filter { taak in
            guard let datum = taak.vervaldatum else { return false }
            return Datums.startVanDag(datum) <= grens
        }.count
    }

    private var aantalInbox: Int {
        openTaken.filter { $0.lijst == nil }.count
    }

    // MARK: Acties

    private var wisBevestiging: Binding<Bool> {
        Binding(
            get: { teWissenLijst != nil },
            set: { open in
                if !open { teWissenLijst = nil }
            }
        )
    }

    private func wis(_ lijst: Lijst, takenBehouden: Bool) {
        let taken = lijst.taken
        for taak in taken {
            if takenBehouden {
                taak.lijst = nil
            } else {
                Herinneringen.annuleer(taak)
                context.delete(taak)
            }
        }
        context.delete(lijst)
        try? context.save()
    }

    private func verplaatsLijsten(van bron: IndexSet, naar doel: Int) {
        var kopie = lijsten
        kopie.move(fromOffsets: bron, toOffset: doel)
        for (index, lijst) in kopie.enumerated() where lijst.volgorde != index {
            lijst.volgorde = index
        }
        try? context.save()
    }

    private func wisTags(_ posities: IndexSet) {
        for positie in posities {
            context.delete(tags[positie])
        }
        try? context.save()
    }
}

#Preview {
    LijstenView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
