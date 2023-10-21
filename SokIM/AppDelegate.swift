// TODO: "Automatically switch to a document's input source"를 InputContext로 구현
// TODO: Safari: 구글 문서, iCloud Pages 한/글/을/입/력 문제... string 가져오기? Safari에서 downgrade 하는 방법 찾기
// TODO: D->M downgrade: NotificationCenter to Context & memory

import Cocoa
import InputMethodKit

func eventHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    theEvent: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus { noErr }

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var server: IMKServer = IMKServer.init(
        // swiftlint:disable:next force_cast
        name: (Bundle.main.infoDictionary!["InputMethodConnectionName"] as! String),
        bundleIdentifier: Bundle.main.bundleIdentifier
    )

    let statusBar = StatusBar()
    let inputMonitor = InputMonitor()

    private var eventHandlerRef: EventHandlerRef?
    private var eventHotKeyRef: EventHotKeyRef?

    private var state = State()
    private var eventContext = EventContext()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debug()

        startMonitorInitially()

        // 사용자가 입력기를 변경하는 시점에 초기화
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetWithInputMonitor),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 사용자가 마우스 클릭하는 시점에 초기화
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown.union(.rightMouseDown).union(.otherMouseDown)) { _ in
            self.reset(withInputMonitor: false)
        }

        // 사용자의 한/A 전환키 조합을 시스템에 등록, 더미 함수 호출
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), eventHotKeyHandler, 1, &eventSpec, nil, &eventHandlerRef)
        registerEventHotKey(Preferences.rotateShortcut)

        // 입력기가 변경되는 시점에 ABC 입력기 제한 로직 실행
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(suppressABC),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 입력기가 변경되는 시점에 보안 입력 상태인 경우 영문 소문자 입력 상태로 초기화
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(abcOnSecureInput),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 잠자기 상태에서 깨어나는 경우 InputMonitor 재시작
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(restartMonitorSilently),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(restartMonitorSilently),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        debug()

        inputMonitor.stop()

        // applicationDidFinishLaunching에서 추가한 observer 제거
        NotificationCenter.default.removeObserver(
            self,
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        unregisterEventHotKey()
        RemoveEventHandler(eventHandlerRef)
    }

    @objc private func startMonitorInitially() {
        debug()

        do {
            notice("모니터 시작 중...")
            try inputMonitor.start()
            statusBar.setStatus("⌨️")
            statusBar.removeMessage()
        } catch {
            warning("\(error)")
            statusBar.setStatus("⚠️")
            statusBar.setMessage("⚠️ \(error)")
            self.perform(#selector(startMonitorInitially), with: nil, afterDelay: 1)
        }
    }

    @objc private func restartMonitorSilently(_ aNotification: Notification) {
        debug("\(aNotification)")

        do {
            notice("모니터 재시작 중...")
            inputMonitor.stop()
            try inputMonitor.start()
        } catch {
            warning("\(error)")
        }
    }

    func registerEventHotKey(_ value: RotateShortcutType) {
        debug()

        unregisterEventHotKey()

        let code: UInt32
        let modifiers: UInt32

        switch value {
        case .capsLock:
            return
        case .rightCommand:
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

        RegisterEventHotKey(
            code,
            modifiers,
            EventHotKeyID(signature: 0, id: 0),
            GetApplicationEventTarget(),
            0,
            &eventHotKeyRef
        )
    }

    func unregisterEventHotKey() {
        debug()

        if eventHotKeyRef != nil {
            UnregisterEventHotKey(eventHotKeyRef)
            eventHotKeyRef = nil
        }
    }

    // 초기화
    @objc private func resetWithInputMonitor() {
        reset(withInputMonitor: true)
    }

    private func reset(withInputMonitor: Bool) {
        debug("withInputMonitor: \(withInputMonitor)")

        if let sender = eventContext.sender {
            eventContext.strategy.flush(from: state, to: sender)
        }
        if withInputMonitor {
            inputMonitor.flush()
        }
        state = State(engine: state.engine)
        if getKeyboardCapsLock() {
            setKeyboardCapsLock(enabled: false)
        }
        eventContext = EventContext()
        InputContext.reset()
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        debug("\(String(describing: event)) \(String(describing: sender))")

        guard let event = event,
              let sender = sender as? (IMKTextInput & NSObjectProtocol)
        else {
            return false
        }

        // 별도 처리: 한영키 한자키 英数키 かな/カナ키 입력 시 OS 처리 무시
        if event.keyCode == kVK_JIS_Eisu || event.keyCode == kVK_JIS_Kana {
            return true
        }

        var inputs = inputMonitor.flush()

        // inputs 전처리
        filterContexts(&inputs)
        filterQuirks(&inputs)

        debug("이전 state: \(state)")
        defer { debug("이후 state: \(state)") }

        // event context 처리
        debug("이전 event context: \(eventContext)")
        defer {
            eventContext = EventContext(sender)
            debug("이후 event context: \(eventContext)")
        }

        // event context 변한 경우 완성/조합 초기화
        let interimEventContext = EventContext(sender)
        debug("중간 event context: \(interimEventContext)")
        if eventContext != interimEventContext {
            debug("event context 변경!")
            state.clear(composing: true)
            eventContext = interimEventContext
        }

        // 기존 state 보존
        let oldState = state

        // inputs 입력, 반복 입력인 경우 down 한번 더 입력
        inputs.forEach { state.next($0) }
        if event.isARepeat, let down = state.down { state.next(down) }

        // 별도 처리: modifier 없는 백스페이스 키
        if event.keyCode == kVK_Delete && event.modifierFlags.subtracting(.capsLock).isEmpty {
            // 이전에 조합 중이던 글자에서 백스페이스
            state.deleteBackwardComposing()

            // sender에 입력
            let handled = eventContext.strategy.backspace(from: state, to: sender, with: oldState)

            /*
             처리가 완료된 경우 -> 완성 초기화
             OS가 대신 처리할 것이 있는 경우 -> 완성/조합 초기화
             */
            state.clear(composing: !handled)

            return handled
        }

        if (
            // event가 engine이 처리할 수 없는 글자인 경우
            state.engine.eventToTuple(event) == nil
        ) || (
            // event가 state가 입력할 문자열과 완전히 동일한 경우
            state.composed == event.characters
            && state.composing == ""
        ) {
            // 이전 조합 종료
            eventContext.strategy.flush(from: oldState, to: sender)

            // 완성/조합 초기화
            state.clear(composing: true)

            // OS가 대신 처리하도록 반환
            return false
        }

        // state에 완성/조합된 문자열을 sender에 입력
        eventContext.strategy.insert(from: state, to: sender, with: oldState)

        // 완성 초기화
        state.clear(composing: false)

        // 처리 완료
        return true
    }

    /** 전처리: EventContext와 InputContext 비교하여 입력 정리 */
    private func filterContexts(_ inputs: inout [Input]) {
        debug()

        // 마지막과 동일한 context만 남김, 단 modifier와 modifier+space는 언제나 처리
        guard let last = inputs.last else { return }
        var flags = Array(repeating: false, count: inputs.count)

        for (idx, input) in inputs.enumerated() {
            if input.context == last.context {
                flags[idx] = true
            } else if let modifier = ModifierUsage(rawValue: input.usage) {
                flags[idx] = true

                if input.type == .keyDown {
                    for (jdx, input) in inputs[idx..<inputs.endIndex].enumerated() {
                        if SpecialUsage(rawValue: input.usage) == .space {
                            flags[idx + jdx] = true
                        } else if ModifierUsage(rawValue: input.usage) == modifier && input.type == .keyUp {
                            break
                        }
                    }
                }
            }
        }

        debug("inputs: \(inputs)")
        debug("flags: \(flags)")

        inputs = inputs.indices.filter { flags[$0] }.map { inputs[$0] }
    }

    /** 전처리: 특정 앱에 대해 입력 정리 */
    private func filterQuirks(_ inputs: inout [Input]) {
        debug()

        switch eventContext.bundleIdentifier {
            // 파워포인트의 경우 "엔터" 이벤트가 입력기로 전달되지 않음
        case "com.microsoft.Powerpoint":
            // "엔터" 입력이 있는 경우 이후 입력만 처리, 단 modifier는 언제나 처리
            if let idx = inputs.lastIndex(where: { $0.type == .keyDown && [0x28, 0x58].contains($0.usage) }) {
                inputs = inputs.indices
                    .filter { $0 > idx || ModifierUsage(rawValue: inputs[$0].usage) != nil }
                    .map { inputs[$0] }
                state.clear(composing: true)
            }
        default:
            break
        }
    }

    @objc private func suppressABC(_ aNotification: Notification) {
        debug("\(String(describing: aNotification))")

        guard Preferences.suppressABC == true else { return }

        let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
        guard let current = current else {
            warning("TISCopyCurrentKeyboardInputSource 실패")
            return
        }

        let currentIDOpaque = TISGetInputSourceProperty(current, kTISPropertyInputSourceID)
        guard let currentIDOpaque = currentIDOpaque else {
            warning("TISGetInputSourceProperty 실패")
            return
        }
        let currentID = Unmanaged<CFString>.fromOpaque(currentIDOpaque).takeUnretainedValue() as String

        if currentID != "com.apple.keylayout.ABC" {
            debug("현재 입력기 ABC 아님: \(currentID)")
            return
        }

        let sokArray = TISCreateInputSourceList([
            kTISPropertyInputSourceType: kTISTypeKeyboardInputMode,
            kTISPropertyInputModeID: "com.kiding.inputmethod.sok.mode" as CFString
        ] as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource]
        guard let sokArray = sokArray else {
            warning("TISCreateInputSourceList 실패")
            return
        }

        let sok = sokArray.first
        guard let sok = sok else {
            warning("sokArray.first 실패")
            return
        }

        // "시스템 설정 > 암호" 필드에서는 무한 루프에 빠질 수 있음
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            guard TISSelectInputSource(sok) == 0 else {
                warning("TISSelectInputSource 실패")
                return
            }

            debug("ABC 입력기 제한 성공")
        }
    }

    @objc private func abcOnSecureInput(_ aNotification: Notification) {
        debug("\(String(describing: aNotification))")

        guard IsSecureEventInputEnabled() else { return }

        state.engine = state.engines.A
        statusBar.setEngine(state.engines.A)
        resetWithInputMonitor()

        debug("abcOnSecureInput 성공")
    }
}
