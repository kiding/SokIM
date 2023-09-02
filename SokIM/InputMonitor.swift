// swiftlint:disable force_cast function_body_length cyclomatic_complexity
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

private let kAXManualAccessibility = "AXManualAccessibility" as CFString
private let kAXEnhancedUserInterface = "AXEnhancedUserInterface" as CFString

/**
 키보드 입력 모니터링
 @see https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/HID/new_api_10_5/tn2187.html
 @see https://www.usb.org/sites/default/files/hut1_21_0.pdf
 */
class InputMonitor {
    private let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)
    private var inputs: [Input] = []
    private var context = InputContext()

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

            // 40ms마다 context 수집
            Task {
                while running.context {
                    nextContext()
                    try? await Task.sleep(for: .milliseconds(40))
                }
            }

            // 가장 앞에 있는 앱 바뀔 때마다 AX 활성화
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(activateAX),
                name: NSWorkspace.didActivateApplicationNotification,
                object: nil
            )
            activateAX(nil) // 첫 시작 시 자동으로 가장 앞에 있는 앱 AX 활성화
        }
    }

    func stop() {
        debug()

        if running.hid == true {
            IOHIDManagerClose(hid, 0)
            running.hid = false
        }

        if running.context == true {
            NSWorkspace.shared.notificationCenter.removeObserver(
                self,
                name: NSWorkspace.didActivateApplicationNotification,
                object: nil
            )
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

    /** modifier 키 눌림 상태 (State와 유사) */
    private var modifier: [ModifierUsage: InputType] = [:]

    /** 한/A 전환이 Caps Lock인 경우 Caps Lock이 활성화/비활성화 되는 과정에서 한/A 전환이 진행될 수 있는지 여부를 판단하는 플래그 (State와 유사) */
    private var canCapsLockRotate = true

    /** 한/A 전환이 Caps Lock인 경우 1초 이상 누르고 있음을 탐지하는 타이머 */
    private var capsLockTimer = DispatchWorkItem(block: {})

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

        // usage가 modifier인 경우
        if let key = ModifierUsage(rawValue: usage) {
            modifier[key] = type

            // 별도 처리: 오른쪽 Command: 한/A 표시만 우선 갱신, 실제 처리는 State에서
            if (type, key) == (.keyUp, .rightCommand)
                && Preferences.rotateShortcut == .rightCommand {
                (NSApp.delegate as! AppDelegate).statusBar.rotateEngine()
            }

            // 별도 처리: Caps Lock: 한/A 전환 종류에 따라 상태 및 LED 우선 갱신, 실제 처리는 State에서
            if (type, key) == (.keyDown, .capsLock) {
                // 한/A 전환이 Caps Lock인 경우 800ms 이상 누르고 있으면 활성화
                if Preferences.rotateShortcut == .capsLock {
                    let enabled = getKeyboardCapsLock()

                    // Caps Lock 활성 -> 비활성: 한/A 전환 1회 억제
                    if enabled {
                        canCapsLockRotate = false
                    }

                    // Caps Lock 비활성화 및 타이머 초기화
                    setKeyboardCapsLock(enabled: false)
                    capsLockTimer.cancel()
                    capsLockTimer = DispatchWorkItem { [self] in
                        if modifier[.capsLock] == .keyDown {
                            // Caps Lock 비활성 -> 활성: 한/A 전환 1회 억제
                            canCapsLockRotate = false

                            // Caps Lock 활성화
                            setKeyboardCapsLock(enabled: true)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: capsLockTimer)
                }
                // 그 외의 경우 일반 반전 처리
                else {
                    setKeyboardCapsLock(enabled: !getKeyboardCapsLock())
                }
            }

            // 별도 처리: Caps Lock: 한/A 표시만 우선 갱신, 실제 처리는 State에서
            if (type, key) == (.keyUp, .capsLock)
                && Preferences.rotateShortcut == .capsLock {
                if canCapsLockRotate {
                    (NSApp.delegate as! AppDelegate).statusBar.rotateEngine()
                } else {
                    canCapsLockRotate = true
                }
            }
        }
        // 그 외 경우 중 keyDown인 경우
        else if type == .keyDown {
            // Command, Shift, Alt, Control
            let isCommandDown = modifier[.leftCommand] == .keyDown || modifier[.rightCommand] == .keyDown
            let isShiftDown = modifier[.leftShift] == .keyDown || modifier[.rightShift] == .keyDown
            let isControlDown = modifier[.leftControl] == .keyDown || modifier[.rightControl] == .keyDown

            // 별도 처리: Command/Shift/Control + Space: 한/A 표시만 우선 갱신, 실제 처리는 State에서
            if (
                isCommandDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .commandSpace
            ) || (
                isShiftDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .shiftSpace
            ) || (
                isControlDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .controlSpace
            ) {
                (NSApp.delegate as! AppDelegate).statusBar.rotateEngine()
            }
        }

        let input = Input(context: context, timestamp: timestamp, type: type, usage: usage)
        debug("\(input)")

        inputs.append(input)
    }

    private func nextContext() {
        context = InputContext(AXUIElementCreateSystemWide())
    }

    /**
     @see https://www.electronjs.org/docs/latest/tutorial/accessibility/
     @see https://www.chromium.org/developers/design-documents/accessibility/
     @see https://github.com/dexterleng/vimac/issues/325
     */
    @objc private func activateAX(_ noti: Notification?) {
        debug("\(String(describing: noti))")

        // noti로 들어온 앱 또는 가장 앞에 있는 앱의 pid 가져오기
        guard let app = noti?.userInfo?["NSWorkspaceApplicationKey"] as? NSRunningApplication
                ?? NSWorkspace.shared.frontmostApplication else {
            return
        }

        // 별도의 스레드에서 진행
        Task {
            let appRef = AXUIElementCreateApplication(app.processIdentifier)

            // AXManualAccessibility
            var axmaValuePkd: CFTypeRef?
            var shouldSetAXMA = true
            if AXUIElementCopyAttributeValue(appRef, kAXManualAccessibility, &axmaValuePkd) == .success {
                let axmaValue = axmaValuePkd as! CFBoolean
                if axmaValue == kCFBooleanTrue {
                    debug("AXManualAccessibility 이미 활성화되어 있음 \(appRef)")
                    shouldSetAXMA = false
                }
            }
            if shouldSetAXMA {
                debug("AXManualAccessibility 활성화 완료 \(appRef)")
                AXUIElementSetAttributeValue(appRef, kAXManualAccessibility, kCFBooleanTrue)
            }

            // AXEnhancedUserInterface
            var axeuiValuePkd: CFTypeRef?
            var shouldSetAXEUI = true
            if AXUIElementCopyAttributeValue(appRef, kAXEnhancedUserInterface, &axeuiValuePkd) == .success {
                let axeuiValue = axeuiValuePkd as! CFBoolean
                if axeuiValue == kCFBooleanTrue {
                    debug("AXEnhancedUserInterface 이미 활성화되어 있음 \(appRef)")
                    shouldSetAXEUI = false
                }
            }
            if shouldSetAXEUI {
                debug("AXEnhancedUserInterface 활성화 \(appRef)")
                AXUIElementSetAttributeValue(appRef, kAXEnhancedUserInterface, kCFBooleanTrue)
            }
        }
    }
}
// swiftlint:enable force_cast function_body_length cyclomatic_complexity
