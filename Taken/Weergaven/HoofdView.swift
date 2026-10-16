import SwiftData
import SwiftUI

struct HoofdView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("welkomGetoond") private var welkomGetoond = false

    var body: some View {
        TabView {
            VandaagView()
                .tabItem { Label("Vandaag", systemImage: "sun.max") }
            LijstenView()
                .tabItem { Label("Lijsten", systemImage: "tray.full") }
            KalenderView()
                .tabItem { Label("Kalender", systemImage: "calendar") }
            ZoekView()
                .tabItem { Label("Zoeken", systemImage: "magnifyingglass") }
        }
        .task {
            if !welkomGetoond {
                Welkom.maakVoorbeeldtaken(in: context)
                welkomGetoond = true
            }
        }
    }
}

#Preview {
    HoofdView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
