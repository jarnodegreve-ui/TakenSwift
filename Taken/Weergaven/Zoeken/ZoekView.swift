import SwiftData
import SwiftUI

/// Zoekt in titels en notities van alle taken.
struct ZoekView: View {
    @Query(sort: \Taak.volgorde) private var alleTaken: [Taak]
    @State private var tekst = ""

    var body: some View {
        NavigationStack {
            List {
                if !zoekterm.isEmpty {
                    let open = resultaten.filter { !$0.afgewerkt }
                    let klaar = resultaten.filter { $0.afgewerkt }
                    if !open.isEmpty {
                        Section("Open") {
                            ForEach(open) { taak in
                                NavigationLink(value: taak) {
                                    TaakRij(taak: taak, toonLijst: true)
                                }
                            }
                        }
                    }
                    if !klaar.isEmpty {
                        Section("Afgewerkt") {
                            ForEach(klaar) { taak in
                                NavigationLink(value: taak) {
                                    TaakRij(taak: taak, toonLijst: true)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if zoekterm.isEmpty {
                    ContentUnavailableView {
                        Label("Zoek in je taken", systemImage: "magnifyingglass")
                    } description: {
                        Text("Zoek op een woord uit de titel of de notities.")
                    }
                } else if resultaten.isEmpty {
                    ContentUnavailableView.search(text: zoekterm)
                }
            }
            .searchable(text: $tekst, prompt: "Zoek taken")
            .navigationTitle("Zoeken")
            .navigationDestination(for: Taak.self) { taak in
                TaakDetailView(taak: taak)
            }
        }
    }

    private var zoekterm: String {
        tekst.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var resultaten: [Taak] {
        let term = zoekterm
        guard !term.isEmpty else { return [] }
        return alleTaken.filter {
            $0.titel.localizedCaseInsensitiveContains(term) || $0.notities.localizedCaseInsensitiveContains(term)
        }
    }
}

#Preview {
    ZoekView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
