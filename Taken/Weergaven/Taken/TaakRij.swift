import SwiftUI

/// Eén taak in een lijst: vinkje, titel, en op de tweede regel datum, subtaken, tags en lijst.
struct TaakRij: View {
    let taak: Taak
    var toonLijst = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation { taak.markeer(afgewerkt: !taak.afgewerkt) }
            } label: {
                Image(systemName: taak.afgewerkt ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(vinkKleur)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(taak.afgewerkt ? "Heropenen" : "Afwerken")

            VStack(alignment: .leading, spacing: 3) {
                Text(taak.titel.isEmpty ? "Naamloze taak" : taak.titel)
                    .strikethrough(taak.afgewerkt)
                    .foregroundStyle(taak.afgewerkt ? Color.secondary : Color.primary)
                if !taak.notities.isEmpty {
                    Text(taak.notities)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if heeftDetails {
                    HStack(spacing: 10) {
                        details
                    }
                    .font(.caption)
                    .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            if taak.prioriteit != .geen && !taak.afgewerkt {
                Image(systemName: "flag.fill")
                    .font(.caption)
                    .foregroundStyle(taak.prioriteit.kleur)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 2)
    }

    private var vinkKleur: Color {
        if taak.afgewerkt { return .secondary }
        return taak.prioriteit == .geen ? Color.secondary : taak.prioriteit.kleur
    }

    private var heeftDetails: Bool {
        taak.vervaldatum != nil
            || !taak.subtaken.isEmpty
            || !taak.tags.isEmpty
            || (toonLijst && taak.lijst != nil)
    }

    @ViewBuilder
    private var details: some View {
        if let datum = taak.vervaldatum {
            Label(Datums.samenvatting(datum, metTijd: taak.heeftTijd), systemImage: "calendar")
                .foregroundStyle(taak.verlopen ? Color.red : Color.secondary)
        }
        if !taak.subtaken.isEmpty {
            Label("\(taak.aantalSubtakenAfgewerkt)/\(taak.subtaken.count)", systemImage: "checklist")
                .foregroundStyle(.secondary)
        }
        ForEach(taak.gesorteerdeTags) { tag in
            Text("#" + tag.naam)
                .foregroundStyle(tag.kleur.kleur)
        }
        if toonLijst, let lijst = taak.lijst {
            Label(lijst.naam, systemImage: lijst.icoon)
                .foregroundStyle(.secondary)
        }
    }
}
