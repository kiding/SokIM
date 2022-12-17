// swiftlint:disable force_cast
import ApplicationServices
import AppKit
import IOKit.hid

struct Input: CustomStringConvertible {
    let context: InputContext
    let timestamp: UInt64
    let type: InputType
    var usage: UInt32

    var description: String { "(\(context), \(timestamp), \(type), \(String(format: "0x%X", usage)))" }
}

enum InputType: String {
    case keyDown
    case keyUp
}

enum InputMonitorError: Error, CustomStringConvertible {
    case failedToOpen(IOReturn)
    case notTrusted

    var description: String {
        switch self {
        case .failedToOpen(let res):
            debug("\(res)")

            switch res {
            case kIOReturnNotPermitted:
                return "입력 모니터링 권한을 허용해 주세요."
            case kIOReturnExclusiveAccess:
                return "키보드 입력을 모니터링하는 다른 앱이 있으면 종료해 주세요."
            default:
                if let cStr = mach_error_string(res) {
                    return String(cString: cStr)
                } else {
                    return "알 수 없는 오류가 발생했습니다. (\(res))"
                }
            }
        case .notTrusted:
            return "손쉬운 사용 권한을 허용해 주세요."
        }
    }
}

private let kAXAppAttr = kAXFocusedApplicationAttribute as CFString
private let kAXElemAttr = kAXFocusedUIElementAttribute as CFString
private let kAXParentAttr = kAXParentAttribute as CFString
private let kAXRoleAttr = kAXRoleAttribute as CFString
private let kAXPosAttr = kAXPositionAttribute as CFString
private let kAXSizeAttr = kAXSizeAttribute as CFString

/**
 키보드 입력 모니터링
 @see https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/HID/new_api_10_5/tn2187.html
 @see https://www.usb.org/sites/default/files/hut1_21_0.pdf
 */
class InputMonitor {
    private let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)
    private var inputs: [Input] = []
    private var context = InputContext(nil, nil)

    init() {
        debug()

        IOHIDManagerSetDeviceMatching(hid, [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,   // Generic Desktop Page (0x01)
            kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard          // Keyboard (0x06, Collection Application)
        ] as CFDictionary)
        IOHIDManagerSetInputValueMatching(hid, [
            kIOHIDElementUsagePageKey: kHIDPage_KeyboardOrKeypad // Keyboard/Keypad (0x07, Selectors or Dynamic Flags)
        ] as CFDictionary)
        IOHIDManagerRegisterInputValueCallback(
            hid, { context, result, sender, value in
                guard result == kIOReturnSuccess else { return }

                // sender로 IOHIDDevice가 전달됨
                guard let sender = sender else { return }
                let unmanagedDevice = Unmanaged<IOHIDDevice>.fromOpaque(sender).takeUnretainedValue()

                // context로 self 포인터가 전달됨
                guard let context = context else { return }
                let unmanagedSelf = Unmanaged<InputMonitor>.fromOpaque(context).takeUnretainedValue()

                unmanagedSelf.nextHID(value, unmanagedDevice)
            },
            // context로 self 포인터 전달
            Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerScheduleWithRunLoop(hid, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    deinit {
        debug()

        IOHIDManagerUnscheduleFromRunLoop(hid, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerRegisterInputValueCallback(hid, nil, nil)
    }

    private var running = (hid: false, context: false)

    func start() throws {
        debug()

        if running.hid == false {
            let res = IOHIDManagerOpen(hid, 0)
            if res != kIOReturnSuccess {
                IOHIDManagerClose(hid, 0)

                throw InputMonitorError.failedToOpen(res)
            }

            running.hid = true
        }

        if running.context == false {
            if !AXIsProcessTrusted() {
                throw InputMonitorError.notTrusted
            }

            running.context = true

            Task {
                while running.context {
                    nextContext()
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
    }

    func stop() {
        debug()

        if running.hid == true {
            IOHIDManagerClose(hid, 0)
            running.hid = false
        }

        if running.context == true {
            running.context = false
        }
    }

    @discardableResult
    func flush() -> [Input] {
        debug()

        // 같은 timestamp일 때 usage 값이 높은 입력을 우선함. 예: Shift+ㅅ 등.
        let result = inputs
            .sorted { $0.usage > $1.usage }
            .sorted { $0.timestamp < $1.timestamp }
        inputs = []

        return result
    }

    private func nextHID(_ value: IOHIDValue, _ device: IOHIDDevice) {
        let timestamp = IOHIDValueGetTimeStamp(value)
        let type: InputType = IOHIDValueGetIntegerValue(value) != 0 ? .keyDown : .keyUp
        var usage = IOHIDElementGetUsage(IOHIDValueGetElement(value))

        // 선처리: USB HID가 허용하는 범위 외에는 무시
        guard 0x04 <= usage && usage <= 0xE7 else { return }

        // 별도 처리: modifier인 경우 "보조 키(Modifier Keys)" 매핑 설정 확인 후 usage 덮어씌우기
        if ModifierUsage(rawValue: usage) != nil {
            usage = getMappedModifierUsage(usage, device)
        }

        // 별도 처리: Caps Lock Down: 한/A 상태 갱신
        if (type, usage) == (.keyDown, ModifierUsage.capsLock.rawValue)
            && Preferences.rotateShortcut == .capsLock {
            (NSApp.delegate as! AppDelegate).statusBar.rotateEngine()
        }

        // 별도 처리: Caps Lock Up: 상태 및 LED 자동으로 끄기
        if (type, usage) == (.keyUp, ModifierUsage.capsLock.rawValue) {
            setKeyboardCapsLock(enabled: false)
        }

        let input = Input(context: context, timestamp: timestamp, type: type, usage: usage)
        debug("\(input)")

        inputs.append(input)
    }

    private func nextContext() {
        debug()

        let system = AXUIElementCreateSystemWide()

        // 포커스가 있는 앱의 bundleIdentifier 가져오기
        var bundleIdentifier: String?
        for _ in 0..<30 {
            bundleIdentifier = getBundleIdentifier(system)
            if bundleIdentifier != nil { break }
        }
        if bundleIdentifier == nil {
            bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        }

        // 포커스가 있는 AXUIElement의 CGRect 가져오기
        var elementRect: CGRect?
        for _ in 0..<30 {
            elementRect = getElementRect(system)
            if elementRect != nil { break }
        }

        context = InputContext(bundleIdentifier, elementRect)
    }

    private func getBundleIdentifier(_ system: AXUIElement) -> String? {
        var appPkd: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXAppAttr, &appPkd) == .success else { return nil }
        let app = appPkd as! AXUIElement

        var pid: pid_t = -1
        guard AXUIElementGetPid(app, &pid) == .success else { return nil }

        return NSWorkspace.shared
            .runningApplications
            .filter { $0.processIdentifier == pid }
            .first?
            .bundleIdentifier
    }

    private func getElementRect(_ system: AXUIElement) -> CGRect? {
        // element 가져오기
        var elementPkd: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXElemAttr, &elementPkd) == .success else { return nil }
        var element = elementPkd as! AXUIElement

        // 부모 element가 있는지 확인하고
        var parentElementPkd: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXParentAttr, &parentElementPkd) == .success {
            let parentElement = parentElementPkd as! AXUIElement

            // role이 있는지 확인하고
            var parentRolePkd: CFTypeRef?
            if AXUIElementCopyAttributeValue(parentElement, kAXRoleAttr, &parentRolePkd) == .success {
                let parentRole = parentRolePkd as! String

                // AXScrollArea면 부모를 대신 사용
                if parentRole == "AXScrollArea" {
                    element = parentElement
                }
            }
        }

        // Position 가져오기
        var axPositionPkd: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPosAttr, &axPositionPkd) == .success else { return nil }
        let axPosition = axPositionPkd as! AXValue

        var cgPosition = CGPoint()
        guard AXValueGetValue(axPosition, .cgPoint, &cgPosition) else { return nil }

        // Size 가져오기
        var axSizePkd: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSizeAttr, &axSizePkd) == .success else { return nil }
        let axSize = axSizePkd as! AXValue

        var cgSize = CGSize()
        guard AXValueGetValue(axSize, .cgSize, &cgSize) else { return nil }

        return CGRect(origin: cgPosition, size: cgSize)
    }
}
