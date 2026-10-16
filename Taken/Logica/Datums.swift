import Foundation

/// Datumrekenwerk. Alles gebruikt dezelfde kalender: gregoriaans, Nederlands (België),
/// week begint op maandag, weeknummers volgens ISO.
enum Datums {
    static let taal = Locale(identifier: "nl_BE")

    static var kalender: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.locale = taal
        k.firstWeekday = 2
        k.minimumDaysInFirstWeek = 4
        return k
    }

    // MARK: Rekenen

    static func startVanDag(_ datum: Date) -> Date {
        kalender.startOfDay(for: datum)
    }

    static func startVanMaand(_ datum: Date) -> Date {
        let k = kalender
        let onderdelen = k.dateComponents([.year, .month], from: datum)
        return k.date(from: onderdelen) ?? startVanDag(datum)
    }

    static func plusDagen(_ aantal: Int, vanaf datum: Date) -> Date {
        kalender.date(byAdding: .day, value: aantal, to: datum) ?? datum
    }

    static func plusMaanden(_ aantal: Int, vanaf datum: Date) -> Date {
        kalender.date(byAdding: .month, value: aantal, to: datum) ?? datum
    }

    static func zelfdeDag(_ a: Date, _ b: Date) -> Bool {
        kalender.isDate(a, inSameDayAs: b)
    }

    static func zelfdeMaand(_ a: Date, _ b: Date) -> Bool {
        kalender.isDate(a, equalTo: b, toGranularity: .month)
    }

    static func isVandaag(_ datum: Date, nu: Date = .now) -> Bool {
        zelfdeDag(datum, nu)
    }

    /// Aantal kalenderdagen van `van` tot `tot`; negatief als `tot` vroeger ligt.
    static func dagenVerschil(van: Date, tot: Date) -> Int {
        let k = kalender
        return k.dateComponents([.day], from: k.startOfDay(for: van), to: k.startOfDay(for: tot)).day ?? 0
    }

    /// Zet uur en minuut op een dag.
    static func metTijd(_ datum: Date, uur: Int, minuut: Int) -> Date {
        kalender.date(bySettingHour: uur, minute: minuut, second: 0, of: datum) ?? datum
    }

    /// De dag van `dag` met het uur en de minuut van `tijd`.
    static func combineer(dag: Date, tijd: Date) -> Date {
        let onderdelen = kalender.dateComponents([.hour, .minute], from: tijd)
        return metTijd(dag, uur: onderdelen.hour ?? 9, minuut: onderdelen.minute ?? 0)
    }

    static func uur(_ datum: Date) -> Int {
        kalender.component(.hour, from: datum)
    }

    static func dagVanMaand(_ datum: Date) -> Int {
        kalender.component(.day, from: datum)
    }

    static func weekNummer(_ datum: Date) -> Int {
        kalender.component(.weekOfYear, from: datum)
    }

    /// Het eerstvolgende hele uur na `nu`.
    static func volgendHeelUur(na nu: Date = .now) -> Date {
        let later = kalender.date(byAdding: .hour, value: 1, to: nu) ?? nu
        return metTijd(later, uur: uur(later), minuut: 0)
    }

    // MARK: Reeksen

    /// De zeven dagen van de week waarin `datum` valt, te beginnen bij maandag.
    static func week(rond datum: Date) -> [Date] {
        let k = kalender
        let dag = k.startOfDay(for: datum)
        let weekdag = k.component(.weekday, from: dag)
        let verschuiving = (weekdag - k.firstWeekday + 7) % 7
        let maandag = plusDagen(-verschuiving, vanaf: dag)
        return (0..<7).map { plusDagen($0, vanaf: maandag) }
    }

    /// Alle dagen van het maandrooster: volledige weken, dus ook dagen van de buurmaanden.
    static func maandRooster(_ maand: Date) -> [Date] {
        let k = kalender
        let eerste = startVanMaand(maand)
        let weekdag = k.component(.weekday, from: eerste)
        let verschuiving = (weekdag - k.firstWeekday + 7) % 7
        let aantalDagen = k.range(of: .day, in: .month, for: eerste)?.count ?? 30
        let rijen = (verschuiving + aantalDagen + 6) / 7
        let begin = plusDagen(-verschuiving, vanaf: eerste)
        return (0..<(rijen * 7)).map { plusDagen($0, vanaf: begin) }
    }

    /// Korte namen van de weekdagen in de volgorde van de week: ma, di, wo, ...
    static var weekdagNamen: [String] {
        let k = kalender
        let namen = k.shortWeekdaySymbols
        let start = k.firstWeekday - 1
        return (0..<7).map { namen[(start + $0) % 7] }
    }

    // MARK: Tekst

    /// "Vandaag", "Morgen", "Gisteren", binnen de week de weekdag, anders "20 okt" of "20 okt 2025".
    static func relatieveNaam(_ datum: Date, nu: Date = .now) -> String {
        switch dagenVerschil(van: nu, tot: datum) {
        case 0: return "Vandaag"
        case 1: return "Morgen"
        case -1: return "Gisteren"
        case 2...6: return weekdag(datum, lang: true)
        default:
            let k = kalender
            if k.component(.year, from: datum) == k.component(.year, from: nu) {
                return datum.formatted(.dateTime.day().month(.abbreviated).locale(taal))
            }
            return datum.formatted(.dateTime.day().month(.abbreviated).year().locale(taal))
        }
    }

    /// "Vandaag", "Morgen", "Gisteren", anders "zaterdag 18 okt" met hoofdletter.
    static func dagTitel(_ datum: Date, nu: Date = .now) -> String {
        switch dagenVerschil(van: nu, tot: datum) {
        case 0: return "Vandaag"
        case 1: return "Morgen"
        case -1: return "Gisteren"
        default:
            return metHoofdletter(datum.formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(taal)))
        }
    }

    /// "Donderdag" of "do".
    static func weekdag(_ datum: Date, lang: Bool = false) -> String {
        metHoofdletter(datum.formatted(.dateTime.weekday(lang ? .wide : .abbreviated).locale(taal)))
    }

    /// "09:30"
    static func tijd(_ datum: Date) -> String {
        datum.formatted(.dateTime.hour().minute().locale(taal))
    }

    /// "do 16 okt"
    static func kort(_ datum: Date) -> String {
        datum.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(taal))
    }

    /// "16 okt"
    static func dagEnMaand(_ datum: Date) -> String {
        datum.formatted(.dateTime.day().month(.abbreviated).locale(taal))
    }

    /// "Donderdag 16 oktober 2026"
    static func lang(_ datum: Date) -> String {
        metHoofdletter(datum.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(taal)))
    }

    /// "Oktober 2026"
    static func maandTitel(_ datum: Date) -> String {
        metHoofdletter(datum.formatted(.dateTime.month(.wide).year().locale(taal)))
    }

    /// Datum met eventueel tijd, zoals in een rij: "Morgen 14:00" of "20 okt".
    static func samenvatting(_ datum: Date, metTijd: Bool) -> String {
        metTijd ? relatieveNaam(datum) + " " + tijd(datum) : relatieveNaam(datum)
    }

    static func metHoofdletter(_ tekst: String) -> String {
        guard let eerste = tekst.first else { return tekst }
        return String(eerste).uppercased() + String(tekst.dropFirst())
    }
}
