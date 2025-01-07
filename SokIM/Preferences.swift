import Cocoa

enum RotateShortcutType: String {
    case capsLock = "CapsLock"
    case rightCommand = "RightCommand"
    case commandSpace = "CommandSpace"
    case shiftSpace = "ShiftSpace"
    case controlSpace = "ControlSpace"
}

struct Preferences {
    /** 한/A 전환키 */

    static var rotateShortcut: RotateShortcutType {
        get { RotateShortcutType(rawValue: UserDefaults.standard.string(forKey: "RotateShortcut") ?? "") ?? .capsLock }
        set(new) {
            UserDefaults.standard.set(new.rawValue, forKey: "RotateShortcut")
            AppDelegate.shared().restartMonitors()
        }
    }

    /** 기타 설정 */

    static var graveOverWon: Bool {
        get { UserDefaults.standard.bool(forKey: "GraveOverWon") }
        set(new) { UserDefaults.standard.set(new, forKey: "GraveOverWon") }
    }

    static var suppressABC: Bool {
        get { UserDefaults.standard.object(forKey: "SuppressABC") as? Bool ?? true }
        set(new) { UserDefaults.standard.set(new, forKey: "SuppressABC") }
    }

    static var debug: Bool {
        get { UserDefaults.standard.bool(forKey: "Debug") }
        set(new) { UserDefaults.standard.set(new, forKey: "Debug") }
    }
}
