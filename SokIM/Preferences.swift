import Foundation

struct Preferences {
    static var graveOverWon: Bool {
        get { UserDefaults.standard.bool(forKey: "GraveOverWon") }
        set(new) { UserDefaults.standard.set(new, forKey: "GraveOverWon") }
    }

    static var debug: Bool {
        get { UserDefaults.standard.bool(forKey: "Debug") }
        set(new) { UserDefaults.standard.set(new, forKey: "Debug") }
    }
}
