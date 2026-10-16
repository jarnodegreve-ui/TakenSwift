import Foundation
import UserNotifications

/// Lokale meldingen voor herinneringen. Elke taak heeft hoogstens één geplande melding,
/// met `taak.uuid` als kenmerk.
enum Herinneringen {
    static func vraagToestemming() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func toestemming() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Plant de herinnering van een taak opnieuw, of haalt ze weg als ze niet meer hoort
    /// (geen herinnering, afgewerkt, of het moment is al voorbij).
    static func plan(voor taak: Taak) {
        let centrum = UNUserNotificationCenter.current()
        let kenmerk = taak.uuid.uuidString
        centrum.removePendingNotificationRequests(withIdentifiers: [kenmerk])

        guard !taak.afgewerkt, let moment = taak.herinnering, moment > .now else { return }

        let inhoud = UNMutableNotificationContent()
        inhoud.title = taak.titel.isEmpty ? "Taak" : taak.titel
        if let lijst = taak.lijst {
            inhoud.subtitle = lijst.naam
        }
        if let datum = taak.vervaldatum {
            inhoud.body = Datums.samenvatting(datum, metTijd: taak.heeftTijd)
        } else if !taak.notities.isEmpty {
            inhoud.body = taak.notities
        }
        inhoud.sound = .default

        let onderdelen = Datums.kalender.dateComponents([.year, .month, .day, .hour, .minute], from: moment)
        let trigger = UNCalendarNotificationTrigger(dateMatching: onderdelen, repeats: false)
        let verzoek = UNNotificationRequest(identifier: kenmerk, content: inhoud, trigger: trigger)
        centrum.add(verzoek, withCompletionHandler: nil)
    }

    static func annuleer(_ taak: Taak) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taak.uuid.uuidString])
    }
}

/// Toont meldingen ook terwijl de app open staat.
final class MeldingDelegaat: NSObject, UNUserNotificationCenterDelegate {
    static let gedeeld = MeldingDelegaat()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
