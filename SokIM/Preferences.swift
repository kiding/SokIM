import Cocoa

// TODO: #15
enum RotateShortcutType: String {
    case capsLock = "CapsLock"
    case rightCommand = "RightCommand"
    case commandSpace = "CommandSpace"
    case shiftSpace = "ShiftSpace"
    case controlSpace = "ControlSpace"
}

// MARK: -

private struct Defaults {
    enum Key: String {
        case rotateShortcut = "RotateShortcut"
        case rotateShortcuts = "RotateShortcuts"
        case graveOverWon = "GraveOverWon"
        case suppressABC = "SuppressABC"
        case debug = "Debug"
    }

    static let container = UserDefaults.standard

    static func get(_ key: Key) -> RotateShortcutType? {
        if let value = container.string(forKey: key.rawValue) {
            RotateShortcutType(rawValue: value)
        } else {
            nil
        }
    }

    static func get(_ key: Key) -> Set<RotateShortcutType>? {
        if let value = container.array(forKey: key.rawValue) as? [String] {
            Set(value.compactMap { RotateShortcutType(rawValue: $0) })
        } else {
            nil
        }
    }

    static func get(_ key: Key) -> Bool? {
        container.object(forKey: key.rawValue) as? Bool
    }

    static func set(_ key: Key, _ value: Set<RotateShortcutType>) {
        container.set(value.map { $0.rawValue }, forKey: key.rawValue)
    }

    static func set(_ key: Key, _ value: Any) {
        container.set(value, forKey: key.rawValue)
    }
}

// MARK: -

struct Preferences {
    /** 한/A 전환키 */

    private static var _rotateShortcuts = Defaults.get(.rotateShortcuts)
    ?? Set([Defaults.get(.rotateShortcut) ?? .capsLock])
    static var rotateShortcuts: Set<RotateShortcutType> {
        get { _rotateShortcuts }
        set {
            _rotateShortcuts = newValue
            Defaults.set(.rotateShortcuts, newValue)
            AppDelegate.shared().restartMonitors(nil)
        }
    }

    /** 기타 설정 */

    private static var _graveOverWon = Defaults.get(.graveOverWon) ?? false
    static var graveOverWon: Bool {
        get { _graveOverWon }
        set {
            _graveOverWon = newValue
            Defaults.set(.graveOverWon, newValue)
        }
    }

    private static var _suppressABC = Defaults.get(.suppressABC) ?? true
    static var suppressABC: Bool {
        get { _suppressABC }
        set {
            _suppressABC = newValue
            Defaults.set(.suppressABC, newValue)
        }
    }

    private static var _debug = Defaults.get(.debug) ?? false
    static var debug: Bool {
        get { _debug }
        set {
            _debug = newValue
            Defaults.set(.debug, newValue)
        }
    }
}
