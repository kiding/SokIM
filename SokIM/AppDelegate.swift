import Cocoa
import InputMethodKit
import UserNotifications

func appDelegate() -> AppDelegate? {
    return NSApp.delegate as? AppDelegate
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // swiftlint:disable force_cast
    private var server: IMKServer = IMKServer.init(
        name: (Bundle.main.infoDictionary!["InputMethodConnectionName"] as! String),
        bundleIdentifier: Bundle.main.bundleIdentifier
    )
    // swiftlint:enable force_cast

    let statusBar = StatusBar()
    let inputMonitor = InputMonitor()
    let clickMonitor = ClickMonitor()
    let hotKeyMonitor = HotKeyMonitor()

    private var state = State()
    private var sender: IMKTextInput?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debug()

        startCheckingUpdate()
        startMonitorsInitially()

        // 사용자가 입력기를 변경하는 시점에 대부분 버림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearExceptEngine),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 입력기가 변경되는 시점에 ABC 입력기 제한 로직 실행
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(suppressABC),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 입력기가 변경되는 시점에 보안 입력 상태인 경우 모두 버리고 영문 소문자 입력으로 변경
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(abcOnSecureInput),
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        // 잠자기 상태에서 깨어나는 경우 InputMonitor 재시작
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(restartMonitors),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(restartMonitors),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        debug()

        stopMonitors()

        // applicationDidFinishLaunching에서 추가한 observer 제거
        NotificationCenter.default.removeObserver(
            self,
            name: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
    }

    private func startCheckingUpdate() {
        debug()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            var deliveredName = ""

            while true {
                debug()

                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForResource = 15
                let url = URL(string: "https://api.github.com/repos/kiding/SokIM/releases/latest")!
                guard let data = try? await URLSession(configuration: config).data(from: url).0 else {
                    warning("요청 실패: \(url)")
                    return
                }

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let name = json["name"] as? String else {
                    warning("릴리스 이름 파싱 실패")
                    return
                }

                guard let latestString = name.wholeMatch(of: /v[\d.]+ \((\d+)\)/)?.1,
                      let latest = Int(latestString) else {
                    warning("알 수 없는 릴리스 이름: \(name)")
                    return
                }

                guard let currentString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
                      let current = Int(currentString) else {
                    warning("CFBundleVersion 없거나 숫자가 아님")
                    return
                }

                debug("current: \(current), latest: \(latest)")
                if current < latest {
                    await MainActor.run {
                        statusBar.setStatus("📥")
                        statusBar.setNotice("📥 새로운 업데이트가 있습니다.")
                    }

                    if deliveredName != name {
                        deliveredName = name

                        let content = UNMutableNotificationContent()
                        content.title = "속 입력기"
                        content.body = "\(name) 업데이트가 있습니다."
                        let request = UNNotificationRequest(identifier: name, content: content, trigger: nil)
                        _ = try? await center.add(request)
                    }
                }

                _ = try? await Task.sleep(for: .seconds(86400 * 2))
            }
        }
    }

    internal func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        debug()

        statusBar.checkUpdate(sender: nil)
    }

    private func startMonitorsInitially() {
        debug()

        do {
            try inputMonitor.start()
            try clickMonitor.start()
            try hotKeyMonitor.start()
            statusBar.setStatus(state.engine.name)
            statusBar.setError(nil)
        } catch {
            warning("\(error)")
            inputMonitor.stop()
            clickMonitor.stop()
            hotKeyMonitor.stop()
            statusBar.setStatus("⚠️")
            statusBar.setError("⚠️ \(error)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: startMonitorsInitially)
        }
    }

    @objc func restartMonitors(_ aNotification: Notification?) {
        debug("aNotification: \(String(describing: aNotification))")

        do {
            inputMonitor.stop()
            try inputMonitor.start()
            clickMonitor.stop()
            try clickMonitor.start()
            hotKeyMonitor.stop()
            try hotKeyMonitor.start()
            statusBar.setStatus(state.engine.name)
            statusBar.setError(nil)
        } catch {
            warning("\(error)")
            inputMonitor.stop()
            clickMonitor.stop()
            hotKeyMonitor.stop()
            statusBar.setStatus("⚠️")
            statusBar.setError("⚠️ \(error)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.restartMonitors(nil) }
        }
    }

    private func stopMonitors() {
        debug()

        inputMonitor.stop()
        clickMonitor.stop()
        hotKeyMonitor.stop()
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        debug("\(String(describing: event)) \(String(describing: sender))")

        // 처리할 event 또는 sender가 없음, OS가 대신 처리
        guard let event = event,
              let sender = sender as? IMKTextInput
        else {
            return false
        }
        self.sender = sender
        let strategy = strategy(for: sender)

        // 별도 처리: 암호 필드에 포커스된 경우 OS가 대신 처리
        if IsSecureEventInputEnabled() {
            return false
        }

        // 별도 처리: 한영키 한자키 英数키 かな/カナ키 입력 시 OS 처리 무시
        if event.keyCode == kVK_JIS_Eisu || event.keyCode == kVK_JIS_Kana {
            return true
        }

        // inputs 처리 시작
        var inputs = inputMonitor.flush()
        filterInputs(&inputs, event: event)

        // 기존 state 보존
        debug("이전 state: \(state)")
        defer { debug("이후 state: \(state)") }
        let oldState = state

        // inputs 입력, 반복 입력인 경우 down 한번 더 입력
        inputs.forEach { state.next($0) }
        if event.isARepeat, let down = state.down { state.next(down) }

        // modifier 없는 백스페이스 키인 경우
        if event.keyCode == kVK_Delete && event.modifierFlags.subtracting(.capsLock).isEmpty {
            // 조합 중이던 글자에서 백스페이스
            state.backspaceComposing()

            // sender에 백스페이스 반영
            let handled = strategy.backspace(from: state, to: sender, with: oldState.composing)

            /*
             처리가 완료된 경우 -> 완성만 버림
             OS가 대신 처리할 것이 있는 경우 -> 완성/조합 버림
             */
            state.clear(composed: true, composing: !handled)

            return handled
        }

        let tuple = state.engine.eventToTuple(event)
        if (
            // event가 engine이 처리할 수 없는 글자인 경우 (예: Cmd + 방향 키 등)
            tuple == nil
        ) || (
            // event가 state가 입력할 문자열과 완전히 동일한 경우
            state.composed == event.characters
            && state.composing == ""
            // `만 제외
            && event.characters != "`"
        ) {
            // sender에 oldState 그대로 조합 종료 반영
            strategy.commit(from: oldState, to: sender)

            // state 새로운 완성/조합 버림
            state.clear(composed: true, composing: true)

            // OS가 대신 처리하도록 반환
            return false
        }

        // event를 engine이 처리할 수 있는데도 state에 완성/조합된 문자열이 없는 경우
        if state.composed.count == 0 && state.composing.count == 0 {
            // 가능성 1: inputMonitor가 정상적으로 작동하지 않고 있을 수 있으므로 재시작
            inputMonitor.restartIfIdle()

            // 가능성 2: event가 inputs보다 많이 늦어서 직전 handle에서 이미 모두 flush되었을 수 있으므로 완료 반환
            return true
        }

        // sender에 state 새로운 완성/조합 진행 반영
        if !strategy.next(from: state, to: sender, with: oldState.composing) {
            // 입력 실패한 경우 tuple만 입력
            state.clear(composed: true, composing: true)
            if let tuple { state.next(tuple) }
            _ = strategy.next(from: state, to: sender, with: "")
        }

        // state 새로운 완성 버림
        state.clear(composed: true, composing: false)

        // 처리 완료
        return true
    }

    /** 지금까지의 입력 전체 state와 sender에 조합 종료 반영 */
    func commit() {
        debug()

        debug("이전 state: \(state)")
        defer { debug("이후 state: \(state)") }

        if let sender = sender {
            strategy(for: sender).commit(from: state, to: sender)
            self.sender = nil
        }
        state.clear(composed: true, composing: true)
    }

    /** 전처리: 입력 정리 */
    private func filterInputs(_ inputs: inout [Input], event: NSEvent?) {
        debug("inputs: \(inputs)")

        var flags = Array(repeating: false, count: inputs.count)

        // 전체 input 중에 마지막과 동일한 context만 남김
        guard let last = inputs.last else { return }
        for (idx, input) in inputs.enumerated() where input.context == last.context {
            flags[idx] = true
        }

        // 남아있는 input 중에 event와 usage가 같은 것 이전은 버림
        if let event = event, let usage = keyCodeToUsage[Int(event.keyCode)] {
            var endIndex = -1

            for (idx, input) in inputs.enumerated() {
                // 남아있지 않거나 keyDown이 아닌 경우 넘어감
                guard flags[idx], input.type == .keyDown else {
                    continue
                }

                // usage가 같으면 기억 (반복되는 경우 가장 마지막 위치를 기억함)
                if input.usage == usage {
                    endIndex = idx
                }
                // usage가 다르고 기억이 있으면 중단 (앞쪽에 있는 첫번째 군집만 찾음)
                else if endIndex >= 0 {
                    break
                }
            }

            if endIndex >= 0 {
                for idx in 0..<endIndex {
                    flags[idx] = false
                }
            }
        }

        // 전체 input 중에 modifier와 modifier+space는 언제나 남김 // TODO: #15
        for (idx, input) in inputs.enumerated() {
            if let modifier = ModifierUsage(rawValue: input.usage) {
                flags[idx] = true

                // modifier의 keyDown–keyUp 사이에 있는 모든 space는 언제나 남김
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

        debug("flags: \(flags)")

        inputs = inputs.indices.filter { flags[$0] }.map { inputs[$0] }
    }

    /** engine 선택 외 모든 상태 버림 */
    @objc func clearExceptEngine(_ aNotification: Notification?) {
        debug("\(String(describing: aNotification))")

        inputMonitor.flush()
        state = State(engine: state.engine)
        sender = nil
        InputContext.commit()
        setKeyboardCapsLock(enabled: false)
    }

    /** 암호 입력 필드를 위한 ABC 입력기 제한 기능 */
    @objc private func suppressABC(_ aNotification: Notification) {
        debug("\(String(describing: aNotification))")

        guard Preferences.suppressABC == true else { return }

        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            warning("TISCopyCurrentKeyboardInputSource 실패")
            return
        }

        guard let currentIDOpaque = TISGetInputSourceProperty(current, kTISPropertyInputSourceID) else {
            warning("TISGetInputSourceProperty 실패")
            return
        }
        let currentID = Unmanaged<CFString>.fromOpaque(currentIDOpaque).takeUnretainedValue() as String

        guard currentID == "com.apple.keylayout.ABC" || currentID == "com.apple.keylayout.US" else {
            debug("현재 입력기 ABC 아님: \(currentID)")
            return
        }

        guard let sokArray = TISCreateInputSourceList([
            kTISPropertyInputSourceType: kTISTypeKeyboardInputMode,
            kTISPropertyInputModeID: "com.kiding.inputmethod.sok.mode" as CFString
        ] as CFDictionary, false)?.takeRetainedValue() as? [TISInputSource] else {
            warning("TISCreateInputSourceList 실패")
            return
        }

        guard let sok = sokArray.first else {
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

        clearExceptEngine(nil)
        state.engine = state.engines.A
        statusBar.setEngine(state.engines.A)

        debug("abcOnSecureInput 성공")
    }
}
