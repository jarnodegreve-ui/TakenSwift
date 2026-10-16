import SwiftData
import SwiftUI

/// Bewerkt één taak. Wijzigingen worden meteen bewaard.
struct TaakDetailView: View {
    @Bindable var taak: Taak

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Lijst.volgorde) private var lijsten: [Lijst]
    @State private var nieuweSubtaak = ""
    @State private var toonWisBevestiging = false
    @State private var gewist = false
    @FocusState private var subtaakVeldActief: Bool

    var body: some View {
        Group {
            if gewist {
                Color.clear
            } else {
                formulier
            }
        }
        .navigationTitle(taak.lijst?.naam ?? "Inbox")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formulier: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        withAnimation { taak.markeer(afgewerkt: !taak.afgewerkt) }
                    } label: {
                        Image(systemName: taak.afgewerkt ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(taak.afgewerkt ? Color.secondary : Color.accentColor)
                    }
                    .buttonStyle(.borderless)

                    TextField("Titel", text: $taak.titel, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .strikethrough(taak.afgewerkt)
                }
                TextField("Notities", text: $taak.notities, axis: .vertical)
                    .lineLimit(2...12)
            }

            Section("Planning") {
                Toggle("Datum", systemImage: "calendar", isOn: heeftDatum)
                if taak.vervaldatum != nil {
                    DatePicker("Dag", selection: dag, displayedComponents: [.date])
                    Toggle("Tijd", systemImage: "clock", isOn: heeftTijd)
                    if taak.heeftTijd {
                        DatePicker("Tijdstip", selection: tijd, displayedComponents: [.hourAndMinute])
                    }
                }
                Toggle("Herinnering", systemImage: "bell", isOn: heeftHerinnering)
                if taak.herinnering != nil {
                    DatePicker("Moment", selection: herinnering, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section {
                Picker("Prioriteit", selection: $taak.prioriteit) {
                    ForEach(Prioriteit.allCases) { prioriteit in
                        Label(prioriteit.naam, systemImage: prioriteit.symbool)
                            .tag(prioriteit)
                    }
                }
                Picker("Lijst", selection: $taak.lijst) {
                    Text("Inbox").tag(nil as Lijst?)
                    ForEach(lijsten) { lijst in
                        Text(lijst.naam).tag(lijst as Lijst?)
                    }
                }
                NavigationLink {
                    TagKiezerView(taak: taak)
                } label: {
                    LabeledContent("Tags") {
                        if taak.tags.isEmpty {
                            Text("Geen")
                        } else {
                            Text(taak.gesorteerdeTags.map { "#" + $0.naam }.joined(separator: " "))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Section("Subtaken") {
                ForEach(taak.gesorteerdeSubtaken) { subtaak in
                    SubtaakRij(subtaak: subtaak)
                }
                .onDelete(perform: wisSubtaken)
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.secondary)
                    TextField("Subtaak toevoegen", text: $nieuweSubtaak)
                        .focused($subtaakVeldActief)
                        .onSubmit(voegSubtaakToe)
                }
            }

            Section {
                Button("Taak wissen", role: .destructive) {
                    toonWisBevestiging = true
                }
            } footer: {
                Text("Aangemaakt op \(Datums.kort(taak.aangemaaktOp))")
            }
        }
        .confirmationDialog("Taak wissen?", isPresented: $toonWisBevestiging, titleVisibility: .visible) {
            Button("Wissen", role: .destructive, action: wis)
        }
        .onChange(of: taak.titel) { Herinneringen.plan(voor: taak) }
        .onChange(of: taak.herinnering) { Herinneringen.plan(voor: taak) }
        .onChange(of: taak.lijst) { Herinneringen.plan(voor: taak) }
    }

    // MARK: Bindingen

    private var heeftDatum: Binding<Bool> {
        Binding(
            get: { taak.vervaldatum != nil },
            set: { aan in
                withAnimation {
                    taak.zetDatum(aan ? Datums.startVanDag(.now) : nil)
                }
            }
        )
    }

    private var heeftTijd: Binding<Bool> {
        Binding(
            get: { taak.heeftTijd },
            set: { aan in
                withAnimation {
                    taak.zetTijd(aan)
                }
            }
        )
    }

    private var dag: Binding<Date> {
        Binding(
            get: { taak.vervaldatum ?? Datums.startVanDag(.now) },
            set: { nieuw in taak.zetDatum(nieuw) }
        )
    }

    private var tijd: Binding<Date> {
        Binding(
            get: { taak.vervaldatum ?? Datums.metTijd(.now, uur: 9, minuut: 0) },
            set: { nieuw in
                let huidig = taak.vervaldatum ?? nieuw
                taak.vervaldatum = Datums.combineer(dag: huidig, tijd: nieuw)
            }
        )
    }

    private var heeftHerinnering: Binding<Bool> {
        Binding(
            get: { taak.herinnering != nil },
            set: { aan in
                withAnimation {
                    taak.herinnering = aan ? standaardHerinnering : nil
                }
                if aan {
                    Task { _ = await Herinneringen.vraagToestemming() }
                }
            }
        )
    }

    private var herinnering: Binding<Date> {
        Binding(
            get: { taak.herinnering ?? standaardHerinnering },
            set: { nieuw in taak.herinnering = nieuw }
        )
    }

    private var standaardHerinnering: Date {
        let voorstel: Date
        if let datum = taak.vervaldatum {
            voorstel = taak.heeftTijd ? datum : Datums.metTijd(datum, uur: 9, minuut: 0)
        } else {
            voorstel = Datums.metTijd(Datums.plusDagen(1, vanaf: .now), uur: 9, minuut: 0)
        }
        return voorstel > .now ? voorstel : Datums.volgendHeelUur()
    }

    // MARK: Acties

    private func voegSubtaakToe() {
        let titel = nieuweSubtaak.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titel.isEmpty else { return }
        let volgende = (taak.subtaken.map { $0.volgorde }.max() ?? -1) + 1
        let subtaak = Subtaak(titel: titel, volgorde: volgende)
        context.insert(subtaak)
        subtaak.taak = taak
        nieuweSubtaak = ""
        subtaakVeldActief = true
    }

    private func wisSubtaken(_ posities: IndexSet) {
        let gesorteerd = taak.gesorteerdeSubtaken
        for positie in posities {
            context.delete(gesorteerd[positie])
        }
    }

    private func wis() {
        Herinneringen.annuleer(taak)
        let teWissen = taak
        gewist = true
        dismiss()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            context.delete(teWissen)
            try? context.save()
        }
    }
}

/// Eén subtaak: vinkje en bewerkbare titel.
struct SubtaakRij: View {
    @Bindable var subtaak: Subtaak

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { subtaak.afgewerkt.toggle() }
            } label: {
                Image(systemName: subtaak.afgewerkt ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(subtaak.afgewerkt ? Color.secondary : Color.accentColor)
            }
            .buttonStyle(.borderless)
            TextField("Subtaak", text: $subtaak.titel)
                .strikethrough(subtaak.afgewerkt)
                .foregroundStyle(subtaak.afgewerkt ? Color.secondary : Color.primary)
        }
    }
}
