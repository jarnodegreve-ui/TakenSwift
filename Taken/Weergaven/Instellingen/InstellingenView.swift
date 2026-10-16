import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// Meldingen, opruimen en versie.
struct InstellingenView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query private var alleTaken: [Taak]
    @State private var toestemming: UNAuthorizationStatus = .notDetermined
    @State private var toonWisBevestiging = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Meldingen") {
                    LabeledContent("Toestemming", value: toestemmingTekst)
                    if toestemming == .notDetermined {
                        Button("Toestemming vragen") {
                            Task {
                                _ = await Herinneringen.vraagToestemming()
                                toestemming = await Herinneringen.toestemming()
                            }
                        }
                    } else if toestemming == .denied {
                        Button("Open Instellingen") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                }

                Section("Gegevens") {
                    LabeledContent("Open taken", value: "\(aantalOpen)")
                    LabeledContent("Afgewerkte taken", value: "\(aantalAfgewerkt)")
                    Button("Afgewerkte taken wissen", role: .destructive) {
                        toonWisBevestiging = true
                    }
                    .disabled(aantalAfgewerkt == 0)
                }

                Section {
                    LabeledContent("Versie", value: versie)
                } footer: {
                    Text("Alle gegevens staan alleen op dit toestel.")
                }
            }
            .navigationTitle("Instellingen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gereed") { dismiss() }
                }
            }
            .task {
                toestemming = await Herinneringen.toestemming()
            }
            .confirmationDialog(
                "Alle afgewerkte taken wissen?",
                isPresented: $toonWisBevestiging,
                titleVisibility: .visible
            ) {
                Button("Wissen", role: .destructive, action: wisAfgewerkte)
            }
        }
    }

    private var aantalOpen: Int {
        alleTaken.filter { !$0.afgewerkt }.count
    }

    private var aantalAfgewerkt: Int {
        alleTaken.filter { $0.afgewerkt }.count
    }

    private var toestemmingTekst: String {
        switch toestemming {
        case .authorized, .provisional, .ephemeral: "Toegestaan"
        case .denied: "Geweigerd"
        case .notDetermined: "Nog niet gevraagd"
        @unknown default: "Onbekend"
        }
    }

    private var versie: String {
        let versie = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let bouw = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(versie) (\(bouw))"
    }

    private func wisAfgewerkte() {
        for taak in alleTaken where taak.afgewerkt {
            Herinneringen.annuleer(taak)
            context.delete(taak)
        }
        try? context.save()
    }
}

#Preview {
    InstellingenView()
        .modelContainer(Voorbeeld.container)
        .environment(\.locale, Datums.taal)
}
