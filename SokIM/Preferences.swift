import Cocoa

// TODO: #15
enum RotateShortcutType: String {
    case capsLock = "CapsLock"
    case rightCommand = "RightCommand"
    case rightOption = "RightOption"
    case commandSpace = "CommandSpace"
    case shiftSpace = "ShiftSpace"
    case controlSpace = "ControlSpace"
}

/** 한/A 전환키: 미리 정해진 키 또는 그 외 키의 가상 키 코드, RotateShortcuts에 함께 저장 */
enum RotateKey: RawRepresentable, Hashable {
    case shortcut(RotateShortcutType)
    case keyCode(Int)

    init?(rawValue: String) {
        if let type = RotateShortcutType(rawValue: rawValue) {
            self = .shortcut(type)
        } else if rawValue.hasPrefix("KeyCode:"), let code = Int(rawValue.dropFirst("KeyCode:".count)) {
            self = .keyCode(code)
        } else {
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .shortcut(let type): type.rawValue
        case .keyCode(let code): "KeyCode:\(code)"
        }
    }
}

// MARK: -

private struct Defaults {
    enum Key: String {
        case rotateShortcut = "RotateShortcut"
        case rotateShortcuts = "RotateShortcuts"
        case graveOverWon = "GraveOverWon"
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

    static func get(_ key: Key) -> [RotateKey]? {
        container.stringArray(forKey: key.rawValue)?.compactMap { RotateKey(rawValue: $0) }
    }

    static func get(_ key: Key) -> Bool? {
        container.object(forKey: key.rawValue) as? Bool
    }

    static func set(_ key: Key, _ value: Any) {
        container.set(value, forKey: key.rawValue)
    }
}

// MARK: -

struct Preferences {
    /** 한/A 전환키 */

    private static var _rotateKeys: [RotateKey] = Defaults.get(.rotateShortcuts)
    ?? [.shortcut(Defaults.get(.rotateShortcut) ?? .capsLock)]
    static var rotateKeys: [RotateKey] {
        get { _rotateKeys }
        set {
            _rotateKeys = newValue
            Defaults.set(.rotateShortcuts, newValue.map(\.rawValue))
            // 설정 화면이 먼저 갱신되도록 다음 차례에 재시작
            DispatchQueue.main.async { appDelegate()?.restartMonitors(nil) }
        }
    }

    /** 한/A 전환키 중 미리 정해진 키 */
    static var rotateShortcuts: Set<RotateShortcutType> {
        Set(rotateKeys.compactMap { if case .shortcut(let type) = $0 { type } else { nil } })
    }

    /** 한/A 전환키 중 그 외 키의 가상 키 코드 */
    static var rotateKeyCodes: [Int] {
        rotateKeys.compactMap { if case .keyCode(let code) = $0 { code } else { nil } }
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

    private static var _debug = Defaults.get(.debug) ?? false
    static var debug: Bool {
        get { _debug }
        set {
            _debug = newValue
            Defaults.set(.debug, newValue)
        }
    }
}
