import AppKit

/** 키보드 입력 후 InputMonitor에 의해 HID 값 발생 시점의 context */
struct InputContext {
    /** 입력되는 앱, 샤용자 상황에 따라 달라짐 */
    let bundleIdentifier: String

    init() {
        bundleIdentifier = InputContext.getBundleIdentifier()
    }

    private static func getBundleIdentifier() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    static func == (left: Self, right: Self) -> Bool {
        left.bundleIdentifier == right.bundleIdentifier
    }

    static func != (left: Self, right: Self) -> Bool {
        !(left == right)
    }
}
