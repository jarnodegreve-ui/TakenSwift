import SwiftData
import SwiftUI

/// Kiest de tags van een taak, en maakt er nieuwe aan.
struct TagKiezerView: View {
    let taak: Taak

    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.naam) private var tags: [Tag]
    @State private var nieuweTag = ""

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                    TextField("Nieuwe tag", text: $nieuweTag)
                        .textInputAutocapitalization(.never)
                        .onSubmit(maakTag)
                    if !nieuweTag.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button("Toevoegen", action: maakTag)
                    }
                }
            }
            Section {
                if tags.isEmpty {
                    Text("Nog geen tags. Typ hierboven een naam.")
                        .foregroundStyle(.secondary)
                }
                ForEach(tags) { tag in
                    Button {
                        wissel(tag)
                    } label: {
                        HStack {
                            Image(systemName: "number")
                                .foregroundStyle(tag.kleur.kleur)
                            Text(tag.naam)
                                .foregroundStyle(.primary)
                            Spacer()
                            if bevat(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bevat(_ tag: Tag) -> Bool {
        taak.tags.contains { $0.persistentModelID == tag.persistentModelID }
    }

    private func wissel(_ tag: Tag) {
        withAnimation {
            if let index = taak.tags.firstIndex(where: { $0.persistentModelID == tag.persistentModelID }) {
                taak.tags.remove(at: index)
            } else {
                taak.tags.append(tag)
            }
        }
    }

    private func maakTag() {
        var schoon = nieuweTag.trimmingCharacters(in: .whitespacesAndNewlines)
        while schoon.hasPrefix("#") {
            schoon.removeFirst()
        }
        guard !schoon.isEmpty else { return }
        if let bestaand = tags.first(where: { $0.naam.caseInsensitiveCompare(schoon) == .orderedSame }) {
            if !bevat(bestaand) {
                taak.tags.append(bestaand)
            }
        } else {
            let tag = Tag(naam: schoon)
            context.insert(tag)
            taak.tags.append(tag)
        }
        try? context.save()
        nieuweTag = ""
    }
}
