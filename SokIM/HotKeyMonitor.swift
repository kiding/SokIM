import QuartzCore

enum HotKeyMonitorError: Error, CustomStringConvertible {
    case axProcessNotTrusted
    case failedToCreateTap
    case failedToCreateSource

    var description: String {
        switch self {
        case .axProcessNotTrusted:
            "손쉬운 사용 권한을 허용해 주세요."
        case .failedToCreateTap:
            "알 수 없는 오류가 발생했습니다. (tap)"
        case .failedToCreateSource:
            "알 수 없는 오류가 발생했습니다. (source)"
        }
    }
}

/**
 단축키 모니터링
 - ``ClickMonitor``
 */
class HotKeyMonitor {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    func start() throws {
        debug()

        if tap != nil || source != nil {
            warning("초기화된 tap 또는 source가 이미 있음")
            return
        }

        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(
                1 << CGEventType.keyDown.rawValue
            ),
            callback: { _, type, event, _ in
                debug("\(type) \(event.flags)")
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    appDelegate()?.restartMonitors(nil)
                }

                let flags = Int32(event.flags.rawValue)
                let isRightCommand = (flags & NX_COMMANDMASK != 0) && (flags & NX_DEVICERCMDKEYMASK != 0)
                let isRightOption = (flags & NX_ALTERNATEMASK != 0) && (flags & NX_DEVICERALTKEYMASK != 0)
                debug("isRightCommand: \(isRightCommand), isRightOption: \(isRightOption)")

                // 한/A키로 오른쪽 커맨드, 오른쪽 옵션 사용시 단축키 무시
                if Preferences.rotateShortcuts.contains(.rightCommand) && isRightCommand
                    || Preferences.rotateShortcuts.contains(.rightOption) && isRightOption {
                    debug("단축키 무시")
                    return nil
                } else {
                    return Unmanaged.passUnretained(event)
                }
            },
            userInfo: nil
        )
        guard let tap else {
            warning("CGEvent.tapCreate 실패")
            if AXIsProcessTrusted() {
                throw HotKeyMonitorError.failedToCreateTap
            } else {
                throw HotKeyMonitorError.axProcessNotTrusted
            }
        }
        self.tap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source else {
            warning("CFMachPortCreateRunLoopSource 실패")
            throw HotKeyMonitorError.failedToCreateSource
        }
        self.source = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        debug()

        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            self.tap = nil
        } else {
            notice("초기화된 tap이 없음")
        }

        if let source {
            CFRunLoopSourceInvalidate(source)
            self.source = nil
        } else {
            notice("초기화된 source가 없음")
        }
    }
}

