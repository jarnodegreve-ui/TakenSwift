import SwiftData
import SwiftUI
import UserNotifications

@main
struct TakenApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = MeldingDelegaat.gedeeld
    }

    var body: some Scene {
        WindowGroup {
            HoofdView()
                .environment(\.locale, Datums.taal)
        }
        .modelContainer(for: [Lijst.self, Taak.self, Subtaak.self, Tag.self])
    }
}
