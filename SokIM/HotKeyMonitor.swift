import Carbon.HIToolbox

enum HotKeyMonitorError: Error, CustomStringConvertible {
    case failedToInstall(OSStatus)
    case failedToRegister(OSStatus)

    var description: String {
        switch self {
        case .failedToInstall(let err):
            "알 수 없는 오류가 발생했습니다. (install, \(err))"
        case .failedToRegister(let err):
            "알 수 없는 오류가 발생했습니다. (register, \(err))"
        }
    }
}

/**
 사용자의 한/A 전환키 조합을 시스템에 등록, 더미 함수 호출
 */
class HotKeyMonitor {
    private var eventHandlerRef: EventHandlerRef?
    private var eventHotKeyRefs: [EventHotKeyRef] = []

    func start() throws {
        debug()

        if eventHandlerRef != nil || eventHotKeyRefs.count > 0 {
            warning("초기화된 eventHandlerRef 또는 eventHotKeyRef가 이미 있음")
            return
        }

        /** eventHandlerRef */

        var eventHandlerRef: EventHandlerRef?
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let err1 = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in noErr },
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )
        debug("InstallEventHandler 성공")
        if err1 != 0 {
            warning("InstallEventHandler 실패: \(err1)")
            throw HotKeyMonitorError.failedToInstall(err1)
        }
        self.eventHandlerRef = eventHandlerRef

        /** eventHotKeyRef */

        try Preferences.rotateShortcuts.forEach {
            var eventHotKeyRef: EventHotKeyRef?
            let code: UInt32
            let modifiers: UInt32

            // TODO: #15
            switch $0 {
            case .capsLock:
                debug("HotKey 해당 없음")
                return
            case .rightCommand:
                debug("HotKey 해당 없음")
                return
            case .rightOption:
                debug("HotKey 해당 없음")
                return
            case .commandSpace:
                code = UInt32(kVK_Space)
                modifiers = UInt32(cmdKey)
            case .shiftSpace:
                code = UInt32(kVK_Space)
                modifiers = UInt32(shiftKey)
            case .controlSpace:
                code = UInt32(kVK_Space)
                modifiers = UInt32(controlKey)
            }

            let err2 = RegisterEventHotKey(
                code,
                modifiers,
                EventHotKeyID(signature: 0, id: 0),
                GetApplicationEventTarget(),
                0,
                &eventHotKeyRef
            )
            debug("RegisterEventHotKey 성공: \($0)")
            if err2 != 0 {
                warning("RegisterEventHotKey 실패: \(err2)")
                throw HotKeyMonitorError.failedToRegister(err2)
            }
            eventHotKeyRefs.append(eventHotKeyRef!)
        }
    }

    func stop() {
        debug()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            debug("RemoveEventHandler 성공")
            self.eventHandlerRef = nil
        } else {
            notice("초기화된 eventHandlerRef가 없음")
        }

        if eventHotKeyRefs.count > 0 {
            eventHotKeyRefs.forEach {
                UnregisterEventHotKey($0)
                debug("UnregisterEventHotKey 성공")
            }
            eventHotKeyRefs = []
        } else {
            notice("초기화된 eventHotKeyRef가 없음")
        }
    }
}
