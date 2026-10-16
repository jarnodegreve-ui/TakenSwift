import SwiftData
import SwiftUI

/// Snel een taak toevoegen. Krijgt vanuit de weergave een lijst, datum of tag mee.
struct NieuweTaakView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Lijst.volgorde) private var lijsten: [Lijst]
    @Query private var alleTaken: [Taak]

    @State private var titel = ""
    @State private var notities = ""
    @State private var datum: Date?
    @State private var heeftTijd = false
    @State private var herinnering: Date?
    @State private var prioriteit: Prioriteit = .geen
    @State private var lijst: Lijst?
    @FocusState private var titelActief: Bool

    private let tag: Tag?

    init(lijst: Lijst? = nil, datum: Date? = nil, tag: Tag? = nil) {
        _lijst = State(initialValue: lijst)
        _datum = State(initialValue: datum)
        self.tag = tag
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Wat moet er gebeuren?", text: $titel, axis: .vertical)
                        .font(.title3)
                        .focused($titelActief)
                    TextField("Notities", text: $notities, axis: .vertical)
                        .lineLimit(1...6)
                }

                Section("Wanneer") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            keuzeknop("Vandaag", gekozen: isDag(0)) { kiesDag(0) }
                            keuzeknop("Morgen", gekozen: isDag(1)) { kiesDag(1) }
                            keuzeknop("Volgende week", gekozen: isDag(7)) { kiesDag(7) }
                            keuzeknop("Geen datum", gekozen: datum == nil) {
                                withAnimation {
                                    datum = nil
                                    heeftTijd = false
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    if datum != nil {
                        DatePicker("Dag", selection: dag, displayedComponents: [.date])
                        Toggle("Tijd", isOn: tijdAan)
                        if heeftTijd {
                            DatePicker("Tijdstip", selection: tijd, displayedComponents: [.hourAndMinute])
                        }
                    }
                    Toggle("Herinnering", isOn: herinneringAan)
                    if herinnering != nil {
                        DatePicker("Moment", selection: herinneringMoment, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section {
                    Picker("Prioriteit", selection: $prioriteit) {
                        ForEach(Prioriteit.allCases) { prioriteit in
                            Label(prioriteit.naam, systemImage: prioriteit.symbool)
                                .tag(prioriteit)
                        }
                    }
                    Picker("Lijst", selection: $lijst) {
                        Text("Inbox").tag(nil as Lijst?)
                        ForEach(lijsten) { lijst in
                            Text(lijst.naam).tag(lijst as Lijst?)
                        }
                    }
                    if let tag {
                        LabeledContent("Tag", value: "#" + tag.naam)
                    }
                }
            }
            .navigationTitle("Nieuwe taak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Toevoegen", action: bewaar)
                        .disabled(titel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { titelActief = true }
        }
    }

    // MARK: Bindingen

    private var dag: Binding<Date> {
        Binding(
            get: { datum ?? Datums.startVanDag(.now) },
            set: { nieuw in
                datum = heeftTijd ? Datums.combineer(dag: nieuw, tijd: datum ?? nieuw) : Datums.startVanDag(nieuw)
            }
        )
    }

    private var tijd: Binding<Date> {
        Binding(
            get: { datum ?? Datums.metTijd(.now, uur: 9, minuut: 0) },
            set: { nieuw in
                datum = Datums.combineer(dag: datum ?? nieuw, tijd: nieuw)
            }
        )
    }

    private var tijdAan: Binding<Bool> {
        Binding(
            get: { heeftTijd },
            set: { aan in
                withAnimation {
                    heeftTijd = aan
                    if let huidig = datum {
                        datum = aan ? Datums.metTijd(huidig, uur: 9, minuut: 0) : Datums.startVanDag(huidig)
                    }
                }
            }
        )
    }

    private var herinneringAan: Binding<Bool> {
        Binding(
            get: { herinnering != nil },
            set: { aan in
                withAnimation {
                    herinnering = aan ? standaardHerinnering : nil
                }
                if aan {
                    Task { _ = await Herinneringen.vraagToestemming() }
                }
            }
        )
    }

    private var herinneringMoment: Binding<Date> {
        Binding(
            get: { herinnering ?? standaardHerinnering },
            set: { nieuw in herinnering = nieuw }
        )
    }

    private var standaardHerinnering: Date {
        let voorstel: Date
        if let datum {
            voorstel = heeftTijd ? datum : Datums.metTijd(datum, uur: 9, minuut: 0)
        } else {
            voorstel = Datums.metTijd(Datums.plusDagen(1, vanaf: .now), uur: 9, minuut: 0)
        }
        return voorstel > .now ? voorstel : Datums.volgendHeelUur()
    }

    // MARK: Hulpjes

    private func isDag(_ verschil: Int) -> Bool {
        guard let datum else { return false }
        return Datums.zelfdeDag(datum, Datums.plusDagen(verschil, vanaf: .now))
    }

    private func kiesDag(_ verschil: Int) {
        let dag = Datums.plusDagen(verschil, vanaf: Datums.startVanDag(.now))
        withAnimation {
            datum = heeftTijd ? Datums.combineer(dag: dag, tijd: datum ?? dag) : dag
        }
    }

    private func keuzeknop(_ tekst: String, gekozen: Bool, actie: @escaping () -> Void) -> some View {
        Button(action: actie) {
            Text(tekst)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(gekozen ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(gekozen ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func bewaar() {
        let schoon = titel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !schoon.isEmpty else { return }
        let volgende = (alleTaken.map { $0.volgorde }.max() ?? -1) + 1
        let taak = Taak(
            titel: schoon,
            notities: notities.trimmingCharacters(in: .whitespacesAndNewlines),
            vervaldatum: datum,
            heeftTijd: heeftTijd,
            herinnering: herinnering,
            prioriteit: prioriteit,
            volgorde: volgende
        )
        context.insert(taak)
        taak.lijst = lijst
        if let tag {
            taak.tags.append(tag)
        }
        try? context.save()
        Herinneringen.plan(voor: taak)
        dismiss()
    }
}

#Preview {
    NieuweTaakView(datum: Datums.startVanDag(.now))
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
