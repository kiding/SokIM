import ApplicationServices
import AppKit
import IOKit.hid

struct Input: CustomStringConvertible {
    let context: InputContext
    let timestamp: UInt64
    let type: InputType
    var usage: UInt32

    var description: String { "(\(context), \(timestamp), \(type), \(usage)/\(String(format: "0x%X", usage)))" }
}

enum InputType: String {
    case keyDown
    case keyUp
}

enum InputMonitorError: Error, CustomStringConvertible {
    case failedToOpen(IOReturn)

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
        }
    }
}

/**
 키보드 입력 모니터링
 @see https://developer.apple.com/library/archive/documentation/DeviceDrivers/Conceptual/HID/new_api_10_5/tn2187.html
 @see https://www.usb.org/sites/default/files/hut1_21_0.pdf
 */
class InputMonitor {
    private var hid: IOHIDManager?
    private var inputs: [Input] = []
    private var restartTimer = DispatchWorkItem(block: {})

    func start() throws {
        debug()

        if hid != nil {
            warning("초기화된 hid가 이미 있음")
            return
        }

        let hid = IOHIDManagerCreate(kCFAllocatorDefault, 0)
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

                unmanagedSelf.restartTimer.cancel()
                unmanagedSelf.nextHID(value, unmanagedDevice)
            },
            // context로 self 포인터 전달
            Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerScheduleWithRunLoop(hid, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let res = IOHIDManagerOpen(hid, 0)
        if res != kIOReturnSuccess {
            IOHIDManagerClose(hid, 0)

            warning("IOHIDManagerOpen 실패: \(res)")
            throw InputMonitorError.failedToOpen(res)
        }
        self.hid = hid
    }

    func stop() {
        debug()

        if let hid {
            IOHIDManagerClose(hid, 0)
            IOHIDManagerUnscheduleFromRunLoop(hid, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDManagerRegisterInputValueCallback(hid, nil, nil)
            self.hid = nil
        } else {
            notice("초기화된 hid가 없음")
        }
    }

    func restartIfIdle() {
        debug()

        restartTimer.cancel()
        restartTimer = DispatchWorkItem { [self] in
            debug()

            stop()
            try? start()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: restartTimer)
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

            // 별도 처리: Control, Command, Caps Lock 입력되면 조합 종료
            if type == .keyDown
                && [.leftControl, .rightControl, .leftCommand, .rightCommand, .capsLock].contains(key) {
                appDelegate()?.commit()
            }

            // 별도 처리: 오른쪽 Command: 한/A 표시만 *우선 처리*, 실제 처리는 State에서
            if (type, key) == (.keyDown, .rightCommand)
                && Preferences.rotateShortcuts.contains(.rightCommand) {
                appDelegate()?.statusBar.rotateEngine()
            }

            // 별도 처리: 오른쪽 Option: 조합 종료 후 한/A 표시만 *우선 처리*, 실제 처리는 State에서
            if (type, key) == (.keyDown, .rightOption)
                && Preferences.rotateShortcuts.contains(.rightOption) {
                appDelegate()?.commit()
                appDelegate()?.statusBar.rotateEngine()
            }

            // 별도 처리: Caps Lock: 한/A 상태 및 LED *우선 처리*, 실제 처리는 State에서
            if (type, key) == (.keyDown, .capsLock) {
                if Preferences.rotateShortcuts.contains(.capsLock) {
                    /* 한/A 전환이 Caps Lock인 경우 800ms 이상 누르고 있으면 활성화 */
                    let enabled = getKeyboardCapsLock()

                    // Caps Lock 활성 -> 비활성: 한/A 전환 1회 억제
                    if enabled {
                        canCapsLockRotate = false
                    }

                    // Caps Lock 비활성화 및 타이머 초기화
                    setKeyboardCapsLock(enabled: false)
                    capsLockTimer.cancel()
                    capsLockTimer = DispatchWorkItem { [self] in
                        debug()

                        if modifier[.capsLock] == .keyDown {
                            // Caps Lock 비활성 -> 활성: 한/A 전환 1회 억제
                            canCapsLockRotate = false

                            // Caps Lock 활성화
                            setKeyboardCapsLock(enabled: true)
                            appDelegate()?.statusBar.setEngine(QwertyEngine.self) // TODO: #24
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800), execute: capsLockTimer)

                    /* 한/A 표시만 *우선 처리* */
                    if canCapsLockRotate {
                        appDelegate()?.statusBar.rotateEngine()
                    } else {
                        canCapsLockRotate = true
                    }
                }
                // 그 외의 경우 일반 반전 처리
                else {
                    setKeyboardCapsLock(enabled: !getKeyboardCapsLock())
                }
            }
        }
        // 그 외 경우 중 keyDown인 경우
        else if type == .keyDown {
            // Command, Shift, Option, Control
            let isCommandDown = modifier[.leftCommand] == .keyDown || modifier[.rightCommand] == .keyDown
            let isShiftDown = modifier[.leftShift] == .keyDown || modifier[.rightShift] == .keyDown
            let isControlDown = modifier[.leftControl] == .keyDown || modifier[.rightControl] == .keyDown

            // 별도 처리: Command/Shift/Control + Space: 한/A 표시만 *우선 처리*, 실제 처리는 State에서 // TODO: #15
            if (
                isCommandDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcuts.contains(.commandSpace)
            ) || (
                isShiftDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcuts.contains(.shiftSpace)
            ) || (
                isControlDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcuts.contains(.controlSpace)
            ) {
                appDelegate()?.commit()
                appDelegate()?.statusBar.rotateEngine()
            }
        }

        let input = Input(
            context: InputContext(type: type, usage: usage),
            timestamp: timestamp,
            type: type,
            usage: usage
        )
        debug("\(input)")

        inputs.append(input)
    }
}
