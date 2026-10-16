import SwiftData
import SwiftUI

/// Maakt of bewerkt een lijst: naam, kleur en icoon.
struct LijstBewerkView: View {
    let lijst: Lijst?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var lijsten: [Lijst]
    @State private var naam: String
    @State private var kleur: Kleur
    @State private var icoon: String

    init(lijst: Lijst?) {
        self.lijst = lijst
        _naam = State(initialValue: lijst?.naam ?? "")
        _kleur = State(initialValue: lijst?.kleur ?? .blauw)
        _icoon = State(initialValue: lijst?.icoon ?? "list.bullet")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: icoon)
                            .font(.title2)
                            .foregroundStyle(kleur.kleur)
                            .frame(width: 36)
                        TextField("Naam", text: $naam)
                    }
                }

                Section("Kleur") {
                    KleurKiezer(kleur: $kleur)
                }

                Section("Icoon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(Iconen.keuze, id: \.self) { symbool in
                            Button {
                                icoon = symbool
                            } label: {
                                Image(systemName: symbool)
                                    .font(.title3)
                                    .frame(width: 42, height: 42)
                                    .background(
                                        icoon == symbool ? kleur.kleur.opacity(0.2) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 8)
                                    )
                                    .foregroundStyle(icoon == symbool ? kleur.kleur : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(lijst == nil ? "Nieuwe lijst" : "Lijst bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar", action: bewaar)
                        .disabled(naam.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func bewaar() {
        let schoon = naam.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !schoon.isEmpty else { return }
        if let lijst {
            lijst.naam = schoon
            lijst.kleur = kleur
            lijst.icoon = icoon
        } else {
            let volgende = (lijsten.map { $0.volgorde }.max() ?? -1) + 1
            let nieuw = Lijst(naam: schoon, kleur: kleur, icoon: icoon, volgorde: volgende)
            context.insert(nieuw)
        }
        try? context.save()
        dismiss()
    }
}

/// Rij met kleurbolletjes.
struct KleurKiezer: View {
    @Binding var kleur: Kleur

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
            ForEach(Kleur.allCases) { keuze in
                Button {
                    kleur = keuze
                } label: {
                    Circle()
                        .fill(keuze.kleur)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if kleur == keuze {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(keuze.naam)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LijstBewerkView(lijst: nil)
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
