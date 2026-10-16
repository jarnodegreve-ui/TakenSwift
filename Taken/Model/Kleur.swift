import SwiftUI

/// Kleuren voor lijsten en tags. Gedempt palet, licht en donker bruikbaar.
enum Kleur: Int, CaseIterable, Identifiable, Codable {
    case blauw = 0
    case groen = 1
    case oranje = 2
    case rood = 3
    case paars = 4
    case roze = 5
    case geel = 6
    case grijs = 7

    var id: Int { rawValue }

    var naam: String {
        switch self {
        case .blauw: "Blauw"
        case .groen: "Groen"
        case .oranje: "Oranje"
        case .rood: "Rood"
        case .paars: "Paars"
        case .roze: "Roze"
        case .geel: "Geel"
        case .grijs: "Grijs"
        }
    }

    var kleur: Color {
        switch self {
        case .blauw: Color(red: 0.39, green: 0.67, blue: 0.87)
        case .groen: Color(red: 0.34, green: 0.73, blue: 0.57)
        case .oranje: Color(red: 0.87, green: 0.64, blue: 0.33)
        case .rood: Color(red: 0.87, green: 0.50, blue: 0.58)
        case .paars: Color(red: 0.60, green: 0.52, blue: 0.84)
        case .roze: Color(red: 0.91, green: 0.56, blue: 0.75)
        case .geel: Color(red: 0.88, green: 0.76, blue: 0.34)
        case .grijs: Color(red: 0.56, green: 0.58, blue: 0.62)
        }
    }
}

/// SF Symbols die een lijst als icoon kan krijgen.
enum Iconen {
    static let keuze: [String] = [
        "list.bullet", "briefcase", "house", "cart", "book", "heart",
        "star", "airplane", "car", "bus", "leaf", "gift",
        "gamecontroller", "music.note", "fork.knife", "graduationcap", "dumbbell", "wrench.and.screwdriver",
        "banknote", "person.2", "pawprint", "camera", "paintbrush", "bell",
    ]
}
