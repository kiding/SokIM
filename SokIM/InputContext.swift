import AppKit

/** 글자가 아닌 글쇠(alt, shift 제외)가 입력될 때마다 증가하는 카운터 */
private var counter: UInt64 = 0

/** 키보드 입력 후 InputMonitor에 의해 HID 값 발생 시점의 context */
struct InputContext {
    static func reset() {
        debug()

        counter += 1
    }

    /** 입력되는 앱, 샤용자 상황에 따라 달라짐 */
    let bundleIdentifier: String
    /** counter의 현재 값 */
    let count: UInt64

    init(type: InputType, usage: UInt32) {
        debug("\(type) \(usage)")

        bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""

        // keyDown만 보고 판단, 단축키 조합(예: Cmd+X)은 같은 context로 묶음
        if type == .keyDown {
            // QwertyEngine에서 지원하는 글쇠면 카운트 증가 안 함
            if QwertyEngine.usageToTupleMap[usage] != nil { }
            // Alt인 경우 카운트 증가 안 함
            else if usage == ModifierUsage.leftAlt.rawValue || usage == ModifierUsage.rightAlt.rawValue { }
            // Shift인 경우 카운트 증가 안 함
            else if usage == ModifierUsage.leftShift.rawValue || usage == ModifierUsage.rightShift.rawValue { }
            // 그 외의 모든 글자가 아닌 글쇠인 경우 카운트 증가
            else { InputContext.reset() }
        }

        count = counter
    }

    static func == (left: Self, right: Self) -> Bool {
        debug("\(left) \(right)")

        return left.bundleIdentifier == right.bundleIdentifier
        && left.count == right.count
    }

    static func != (left: Self, right: Self) -> Bool {
        debug("\(left) \(right)")

        return !(left == right)
    }
}
