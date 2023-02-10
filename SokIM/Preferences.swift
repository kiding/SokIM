import Foundation

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
        set(new) { UserDefaults.standard.set(new.rawValue, forKey: "RotateShortcut") }
    }

    /** 기타 설정 */

    static var graveOverWon: Bool {
        get { UserDefaults.standard.bool(forKey: "GraveOverWon") }
        set(new) { UserDefaults.standard.set(new, forKey: "GraveOverWon") }
    }

    static var debug: Bool {
        get { UserDefaults.standard.bool(forKey: "Debug") }
        set(new) { UserDefaults.standard.set(new, forKey: "Debug") }
    }
}
