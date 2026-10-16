import SwiftData
import SwiftUI

/// Kalender met maandrooster (plus de taken van de gekozen dag) en weekoverzicht.
struct KalenderView: View {
    enum Modus: String, CaseIterable, Identifiable {
        case maand = "Maand"
        case week = "Week"

        var id: String { rawValue }
    }

    @Query(sort: \Taak.volgorde) private var alleTaken: [Taak]
    @State private var modus: Modus = .maand
    @State private var gekozenDag = Datums.startVanDag(.now)
    @State private var getoondeMaand = Datums.startVanMaand(.now)
    @State private var toonNieuw = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Weergave", selection: $modus) {
                    ForEach(Modus.allCases) { modus in
                        Text(modus.rawValue).tag(modus)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if modus == .maand {
                    MaandRooster(maand: $getoondeMaand, gekozen: $gekozenDag, telling: tellingPerDag)
                    Divider()
                    dagLijst
                } else {
                    WeekLijst(gekozen: $gekozenDag, taken: alleTaken)
                }
            }
            .navigationTitle("Kalender")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Taak.self) { taak in
                TaakDetailView(taak: taak)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Vandaag") {
                        withAnimation {
                            gekozenDag = Datums.startVanDag(.now)
                            getoondeMaand = Datums.startVanMaand(.now)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toonNieuw = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nieuwe taak")
                }
            }
            .sheet(isPresented: $toonNieuw) {
                NieuweTaakView(datum: gekozenDag)
            }
            .onChange(of: gekozenDag) {
                if !Datums.zelfdeMaand(gekozenDag, getoondeMaand) {
                    getoondeMaand = Datums.startVanMaand(gekozenDag)
                }
            }
        }
    }

    /// Aantal open taken per dag (sleutel: middernacht van die dag).
    private var tellingPerDag: [Date: Int] {
        var telling: [Date: Int] = [:]
        for taak in alleTaken where !taak.afgewerkt {
            if let datum = taak.vervaldatum {
                telling[Datums.startVanDag(datum), default: 0] += 1
            }
        }
        return telling
    }

    private var dagLijst: some View {
        let open = alleTaken
            .filter { !$0.afgewerkt && $0.valtOp(gekozenDag) }
            .sorted { a, b in
                if a.heeftTijd != b.heeftTijd { return !a.heeftTijd }
                if let datumA = a.vervaldatum, let datumB = b.vervaldatum, datumA != datumB { return datumA < datumB }
                if a.prioriteitRaw != b.prioriteitRaw { return a.prioriteitRaw > b.prioriteitRaw }
                return a.volgorde < b.volgorde
            }
        let klaar = alleTaken.filter { $0.afgewerkt && $0.valtOp(gekozenDag) }
        return List {
            Section {
                if open.isEmpty && klaar.isEmpty {
                    Text("Niets gepland")
                        .foregroundStyle(.secondary)
                }
                ForEach(open) { taak in
                    NavigationLink(value: taak) {
                        TaakRij(taak: taak, toonLijst: true)
                    }
                }
                ForEach(klaar) { taak in
                    NavigationLink(value: taak) {
                        TaakRij(taak: taak, toonLijst: true)
                    }
                }
            } header: {
                Text(Datums.lang(gekozenDag))
            }
        }
        .listStyle(.plain)
    }
}

/// Maandrooster: weekdagen bovenaan, een rij per week, stippen onder dagen met taken.
struct MaandRooster: View {
    @Binding var maand: Date
    @Binding var gekozen: Date
    let telling: [Date: Int]

    private let kolommen = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button {
                    verschuif(-1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Vorige maand")
                Spacer()
                Text(Datums.maandTitel(maand))
                    .font(.headline)
                Spacer()
                Button {
                    verschuif(1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Volgende maand")
            }
            .padding(.horizontal)

            LazyVGrid(columns: kolommen, spacing: 0) {
                ForEach(Datums.weekdagNamen, id: \.self) { naam in
                    Text(naam)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: kolommen, spacing: 4) {
                ForEach(Datums.maandRooster(maand), id: \.self) { dag in
                    dagCel(dag)
                }
            }
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 30).onEnded { waarde in
                    if waarde.translation.width < -40 {
                        verschuif(1)
                    } else if waarde.translation.width > 40 {
                        verschuif(-1)
                    }
                }
            )
        }
        .padding(.bottom, 8)
    }

    private func verschuif(_ maanden: Int) {
        withAnimation {
            maand = Datums.plusMaanden(maanden, vanaf: maand)
        }
    }

    private func dagCel(_ dag: Date) -> some View {
        let inMaand = Datums.zelfdeMaand(dag, maand)
        let isGekozen = Datums.zelfdeDag(dag, gekozen)
        let isVandaag = Datums.isVandaag(dag)
        let aantal = telling[Datums.startVanDag(dag)] ?? 0
        let tekstKleur: Color = isGekozen ? .white : (isVandaag ? .accentColor : (inMaand ? .primary : .secondary))
        return Button {
            gekozen = dag
        } label: {
            VStack(spacing: 2) {
                Text("\(Datums.dagVanMaand(dag))")
                    .font(.callout.weight(isVandaag ? .bold : .regular))
                    .frame(width: 34, height: 34)
                    .background(isGekozen ? Color.accentColor : Color.clear, in: Circle())
                    .foregroundStyle(tekstKleur)
                HStack(spacing: 3) {
                    ForEach(0..<min(aantal, 3), id: \.self) { _ in
                        Circle()
                            .fill(inMaand ? Color.accentColor : Color.secondary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Datums.lang(dag))
    }
}

/// Weekoverzicht: de zeven dagen onder elkaar met hun taken.
struct WeekLijst: View {
    @Binding var gekozen: Date
    let taken: [Taak]

    var body: some View {
        let dagen = Datums.week(rond: gekozen)
        return VStack(spacing: 0) {
            HStack {
                Button {
                    verschuif(-7)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Vorige week")
                Spacer()
                Text(titel(dagen))
                    .font(.headline)
                Spacer()
                Button {
                    verschuif(7)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .accessibilityLabel("Volgende week")
            }
            .padding(.horizontal)
            .padding(.bottom, 6)

            List {
                ForEach(dagen, id: \.self) { dag in
                    Section {
                        let vanDag = taken.filter { !$0.afgewerkt && $0.valtOp(dag) }
                        if vanDag.isEmpty {
                            Text("Niets gepland")
                                .foregroundStyle(.tertiary)
                        }
                        ForEach(vanDag) { taak in
                            NavigationLink(value: taak) {
                                TaakRij(taak: taak, toonLijst: true)
                            }
                        }
                    } header: {
                        Text(Datums.dagTitel(dag))
                            .foregroundStyle(Datums.isVandaag(dag) ? Color.accentColor : Color.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func verschuif(_ dagen: Int) {
        withAnimation {
            gekozen = Datums.plusDagen(dagen, vanaf: gekozen)
        }
    }

    private func titel(_ dagen: [Date]) -> String {
        guard let eerste = dagen.first, let laatste = dagen.last else { return "Week" }
        return "Week \(Datums.weekNummer(eerste)): \(Datums.dagEnMaand(eerste)) tot \(Datums.dagEnMaand(laatste))"
    }
}

#Preview {
    KalenderView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
