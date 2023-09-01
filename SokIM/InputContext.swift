// swiftlint:disable force_cast
import AppKit

private let kAXFocusedElemAttr = kAXFocusedUIElementAttribute as CFString
private let kAXRoleAttr = kAXRoleAttribute as CFString
private let kAXParentAttr = kAXParentAttribute as CFString

/** 키보드 입력 후 InputMonitor에 의해 HID 값 발생 시점의 context */
struct InputContext {
    /** 입력되는 앱, 샤용자 상황에 따라 달라짐 */
    let bundleIdentifier: String
    /** 선택된 입력 개체부터 최상위 AXUIElement까지의 Role을 나열한 값 */
    let rolePath: String

    init() {
        bundleIdentifier = ""
        rolePath = ""
    }

    init (_ system: AXUIElement) {
        bundleIdentifier = InputContext.getBundleIdentifier()
        rolePath = InputContext.getRolePath(system)
    }

    private static func getBundleIdentifier() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
    }

    private static func getRolePath(_ system: AXUIElement) -> String {
        // 선택된 element 가져오기
        var elementRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedElemAttr, &elementRef) == .success else {
            return ""
        }
        var element = elementRef as! AXUIElement

        // 최상위 element까지 방문, 최대 50개
        var path = ":"
        for _ in 1..<50 {
            // element의 Role 가져오기
            var elementRoleRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXRoleAttr, &elementRoleRef) == .success else {
                break
            }
            let elementRole = elementRoleRef as! String
            path += "\(elementRole):"

            // 상위 element 가져오기
            var parentRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXParentAttr, &parentRef) == .success else {
                break
            }
            let parent = parentRef as! AXUIElement

            // 상위 element 방문
            element = parent
        }

        return path
    }

    static func == (left: Self, right: Self) -> Bool {
        left.bundleIdentifier == right.bundleIdentifier
        && left.rolePath == right.rolePath
    }

    static func != (left: Self, right: Self) -> Bool {
        !(left == right)
    }
}
// swiftlint:enable force_cast
