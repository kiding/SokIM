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

    private static var _rotateShortcut = RotateShortcutType(
        rawValue: UserDefaults.standard.string(forKey: "RotateShortcut") ?? ""
    ) ?? .capsLock
    static var rotateShortcut: RotateShortcutType {
        get { _rotateShortcut }
        set(new) {
            _rotateShortcut = new
            UserDefaults.standard.set(new.rawValue, forKey: "RotateShortcut")
            AppDelegate.shared().restartMonitors()
        }
    }

    /** 기타 설정 */

    private static var _graveOverWon = UserDefaults.standard.bool(forKey: "GraveOverWon")
    static var graveOverWon: Bool {
        get { _graveOverWon }
        set(new) {
            _graveOverWon = new
            UserDefaults.standard.set(new, forKey: "GraveOverWon")
        }
    }

    private static var _suppressABC = UserDefaults.standard.object(forKey: "SuppressABC") as? Bool ?? true
    static var suppressABC: Bool {
        get { _suppressABC }
        set(new) {
            _suppressABC = new
            UserDefaults.standard.set(new, forKey: "SuppressABC")
        }
    }

    private static var _debug = UserDefaults.standard.bool(forKey: "Debug")
    static var debug: Bool {
        get { _debug }
        set(new) {
            _debug = new
            UserDefaults.standard.set(new, forKey: "Debug")
        }
    }
}
