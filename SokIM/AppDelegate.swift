// TODO: "Automatically switch to a document's input source"를 InputContext로 구현
// TODO: 조합 시 스타일링 (IMKInputController override)
// TODO: 빌드 세팅에 따라 privacy .auto
// TODO: Safari: 구글 문서, iCloud Pages 한/글/을/입/력 문제... string 가져오기? Safari에서 downgrade 하는 방법 찾기
// TODO: D->M downgrade: NotificationCenter to Context & memory

// TODO: ElementRect -> ElementTree (Rect는 바뀔 수 있음)
// TODO: AXManualAccessibility
// TODO: AXEnhancedUserInterface
// TODO: 인스톨러: 재시동, Sparkle

// TODO: Shift+Space 한영전환 시 iTerm에서 Space 입력됨

import Cocoa
import InputMethodKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var server: IMKServer = IMKServer.init(
        // swiftlint:disable:next force_cast
        name: (Bundle.main.infoDictionary!["InputMethodConnectionName"] as! String),
        bundleIdentifier: Bundle.main.bundleIdentifier
    )

    let statusBar = StatusBar()
    let inputMonitor = InputMonitor()

    private var state = State()
    private var eventContext = EventContext()
    private var inputContext = InputContext(nil, nil)

    @objc private func startMonitor() {
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
            self.perform(#selector(startMonitor), with: nil, afterDelay: 1)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debug()

        startMonitor()

        // 사용자가 입력기를 변경하는 시점을 추적하는 observer 추가
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardChangedHandler),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
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
    }

    // 사용자가 입력기를 변경하는 경우 state 초기화
    @objc private func keyboardChangedHandler(_ noti: Notification) {
        debug("\(noti)")

        inputMonitor.flush()
        state = State(engine: state.engine)
        eventContext = EventContext()
        inputContext = (nil, nil)
    }

    // swiftlint:disable:next function_body_length
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        debug("\(String(describing: event)) \(String(describing: sender))")

        guard let event = event,
              let sender = sender as? (IMKTextInput & NSObjectProtocol)
        else {
            return false
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

        // event context 변한 경우 완성/조합/입력 초기화
        let interimEventContext = EventContext(sender)
        debug("중간 event context: \(interimEventContext)")
        if eventContext != interimEventContext {
            debug("event context 변경!")
            state.clear(composing: true)
            eventContext = interimEventContext
        }

        // input context 처리
        debug("이전 input context: \(inputContext)")
        defer { debug("이후 input context: \(inputContext)") }

        // TODO: See :8 ~ :10
        //            // input context 변한 경우 완성/조합/입력 초기화
        //            let interimInputContext = inputs.last?.context ?? (nil, nil)
        //            debug("중간 input context: \(interimInputContext)")
        //            if inputContext != interimInputContext {
        //                debug("input context 변경!")
        //                state.clear(composing: true)
        //                inputContext = interimInputContext
        //            }

        // 별도 처리: 보안 입력 상태인 경우 Monitor가 작동하지 않음
        if IsSecureEventInputEnabled() {
            // Caps Lock 끄기
            setKeyboardCapsLock(enabled: false)

            // modifier 끄기
            state.modifier.removeAll()

            // OS가 처리할 수 있도록 반환
            return false
        }

        // 기존 state 보존
        let oldState = state

        // inputs 입력, 반복 입력인 경우 down 한번 더 입력
        inputs.forEach { state.next($0) }
        if event.isARepeat, let down = state.down { state.next(down) }

        // 최종 처리 여부, false면 OS가 대신 입력
        var handled = true

        // 별도 처리: modifier 없는 백스페이스 키
        if event.keyCode == kVK_Delete && event.modifierFlags.subtracting(.capsLock).isEmpty {
            // 이전에 조합 중이던 글자에서 백스페이스
            state.deleteBackwardComposing()

            // sender에 입력
            handled = eventContext.strategy.backspace(from: state, to: sender, with: oldState)

            // 완성/입력 초기화
            state.clear(composing: false)

            // OS가 대신 처리할 것이 있는 경우
            if handled == false {
                // 완성/조합/입력 초기화
                state.clear(composing: true)
            }

            return handled
        }

        // event가 engine이 처리할 수 없는 글자인 경우
        if state.engine.eventToTuple(event) == nil {
            // OS가 대신 처리하도록 반환
            handled = false
        }

        // state에 완성/조합된 문자열을 sender에 입력
        eventContext.strategy.insert(from: state, to: sender, with: oldState)

        // 완성/입력 초기화
        state.clear(composing: false)

        // OS가 대신 처리할 것이 있는 경우
        if handled == false {
            // 조합 종료
            eventContext.strategy.flush(from: state, to: sender)

            // 완성/조합/입력 초기화
            state.clear(composing: true)
        }

        return handled
    }

    /** 전처리: EventContext와 InputContext 비교하여 입력 정리 */
    private func filterContexts(_ inputs: inout [Input]) {
        debug()

        // 마지막과 동일한 bundleIdentifier만 남김, 단 modifier는 언제나 처리
        if let last = inputs.last {
            inputs = inputs.filter {
                $0.context.bundleIdentifier == last.context.bundleIdentifier
                || ModifierUsage(rawValue: $0.usage) != nil
            }
        }

        // 마지막과 동일한 elementRect만 남김, 단 modifier는 언제나 처리
        if let last = inputs.last {
            inputs = inputs.filter {
                $0.context.elementRect == last.context.elementRect
                || ModifierUsage(rawValue: $0.usage) != nil
            }
        }
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
}
