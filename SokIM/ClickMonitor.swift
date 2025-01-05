import QuartzCore

enum ClickMonitorError: Error, CustomStringConvertible {
    case failedToCreateTap
    case failedToCreateSource

    var description: String {
        switch self {
        case .failedToCreateTap:
            "알 수 없는 오류가 발생했습니다. (tap)"
        case .failedToCreateSource:
            "알 수 없는 오류가 발생했습니다. (source)"
        }
    }
}

/**
 마우스 클릭 모니터링
 @see https://github.com/pqrs-org/Karabiner-Elements/blob/main/DEVELOPMENT.md
 @see https://github.com/pqrs-org/Karabiner-Elements/blob/main/src/share/monitor/event_tap_monitor.hpp
 */
class ClickMonitor {
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
            options: .listenOnly,
            eventsOfInterest: CGEventMask(
                1 << CGEventType.leftMouseDown.rawValue
                | 1 << CGEventType.rightMouseDown.rawValue
                | 1 << CGEventType.otherMouseDown.rawValue),
            callback: { _, _, event, _ in
                // 사용자가 마우스 클릭하는 시점에 초기화
                AppDelegate.shared().reset()
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        )
        guard let tap else {
            throw ClickMonitorError.failedToCreateTap
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source else {
            throw ClickMonitorError.failedToCreateSource
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.source = source
        debug("ClickMonitor 시작 성공")
    }

    func stop() {
        debug()

        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        } else {
            warning("초기화된 tap이 없음")
        }

        if let source {
            CFRunLoopSourceInvalidate(source)
        } else {
            warning("초기화된 source가 없음")
        }

        self.tap = nil
        self.source = nil
        debug("ClickMonitor 중단 성공")
    }
}
