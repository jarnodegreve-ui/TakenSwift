import Foundation
import SwiftData

/// Een afvinkpunt binnen een taak.
@Model
final class Subtaak {
    var titel: String
    var afgewerkt: Bool
    var volgorde: Int
    var taak: Taak?

    init(titel: String, volgorde: Int = 0) {
        self.titel = titel
        self.afgewerkt = false
        self.volgorde = volgorde
    }
}
