import AppKit

/** 글자가 아닌 글쇠(modifier 제외)가 입력될 때마다 증가하는 카운터 */
private var counter: UInt64 = 0

/** 키보드 입력 후 InputMonitor에 의해 HID 값 발생 시점의 context */
struct InputContext {
    static func reset() { counter += 1 }

    /** 입력되는 앱, 샤용자 상황에 따라 달라짐 */
    let bundleIdentifier: String
    /** counter의 현재 값 */
    let count: UInt64

    init(_ usage: UInt32) {
        bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""

        // QwertyEngine에서 지원하는 글쇠면 카운트 증가 안 함
        if QwertyEngine.usageToTupleMap[usage] != nil { }
        // modifier인 경우에도 카운트 증가 안 함
        else if ModifierUsage(rawValue: usage) != nil { }
        // 그 외의 모든 글자가 아닌 글쇠인 경우 카운트 증가
        else { InputContext.reset() }

        count = counter
    }

    static func == (left: Self, right: Self) -> Bool {
        left.bundleIdentifier == right.bundleIdentifier
        && left.count == right.count
    }

    static func != (left: Self, right: Self) -> Bool {
        !(left == right)
    }
}
