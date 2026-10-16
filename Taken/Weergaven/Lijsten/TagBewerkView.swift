import SwiftData
import SwiftUI

/// Maakt of bewerkt een tag: naam en kleur.
struct TagBewerkView: View {
    let tag: Tag?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var naam: String
    @State private var kleur: Kleur

    init(tag: Tag?) {
        self.tag = tag
        _naam = State(initialValue: tag?.naam ?? "")
        _kleur = State(initialValue: tag?.kleur ?? .grijs)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "number")
                            .font(.title2)
                            .foregroundStyle(kleur.kleur)
                            .frame(width: 36)
                        TextField("Naam", text: $naam)
                            .textInputAutocapitalization(.never)
                    }
                }
                Section("Kleur") {
                    KleurKiezer(kleur: $kleur)
                }
            }
            .navigationTitle(tag == nil ? "Nieuwe tag" : "Tag bewerken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar", action: bewaar)
                        .disabled(schoneNaam.isEmpty)
                }
            }
        }
    }

    private var schoneNaam: String {
        var schoon = naam.trimmingCharacters(in: .whitespacesAndNewlines)
        while schoon.hasPrefix("#") {
            schoon.removeFirst()
        }
        return schoon
    }

    private func bewaar() {
        let schoon = schoneNaam
        guard !schoon.isEmpty else { return }
        if let tag {
            tag.naam = schoon
            tag.kleur = kleur
        } else {
            context.insert(Tag(naam: schoon, kleur: kleur))
        }
        try? context.save()
        dismiss()
    }
}
