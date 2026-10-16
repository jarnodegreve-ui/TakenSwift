import Foundation

/// Wat een takenlijst toont: een slimme lijst, een eigen lijst of een tag.
enum Weergave: Hashable {
    case vandaag
    case komende7
    case inbox
    case alles
    case afgewerkt
    case lijst(Lijst)
    case tag(Tag)

    var titel: String {
        switch self {
        case .vandaag: "Vandaag"
        case .komende7: "Komende 7 dagen"
        case .inbox: "Inbox"
        case .alles: "Alles"
        case .afgewerkt: "Afgewerkt"
        case .lijst(let lijst): lijst.naam
        case .tag(let tag): "#" + tag.naam
        }
    }

    var symbool: String {
        switch self {
        case .vandaag: "sun.max"
        case .komende7: "calendar.badge.clock"
        case .inbox: "tray"
        case .alles: "square.stack"
        case .afgewerkt: "checkmark.circle"
        case .lijst(let lijst): lijst.icoon
        case .tag: "number"
        }
    }

    var isLijst: Bool {
        if case .lijst = self { return true }
        return false
    }

    var isTag: Bool {
        if case .tag = self { return true }
        return false
    }

    var lijst: Lijst? {
        if case .lijst(let lijst) = self { return lijst }
        return nil
    }

    var tag: Tag? {
        if case .tag(let tag) = self { return tag }
        return nil
    }

    /// De datum die een nieuwe taak vanuit deze weergave meekrijgt.
    var standaardDatum: Date? {
        switch self {
        case .vandaag, .komende7: Datums.startVanDag(.now)
        default: nil
        }
    }
}
