import SwiftUI
import Carbon.HIToolbox
import IOKit.hid

/** 툴바 탭으로 나뉜 설정 화면 */
func makeSettingsViewController() -> NSViewController {
    let tabs = SettingsTabViewController()
    tabs.tabStyle = .toolbar
    tabs.addTabViewItem(settingsTab("일반", "gearshape", GeneralSettingsView()))
    tabs.addTabViewItem(settingsTab("정보", "info.circle", AboutSettingsView()))
    return tabs
}

/** 선택한 탭 이름을 창 제목으로 사용 */
private class SettingsTabViewController: NSTabViewController {
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.title = tabView.selectedTabViewItem?.label ?? ""
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        view.window?.title = tabViewItem?.label ?? ""
    }
}

private func settingsTab<Content: View>(_ label: String, _ symbol: String, _ view: Content) -> NSTabViewItem {
    let controller = NSHostingController(rootView: view)
    controller.sizingOptions = .preferredContentSize
    controller.title = label

    let item = NSTabViewItem(viewController: controller)
    item.label = label
    item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
    return item
}

// MARK: - 일반

private struct GeneralSettingsView: View {
    @State private var rotateKeys = Preferences.rotateKeys
    @State private var graveOverWon = Preferences.graveOverWon
    @State private var debugMode = Preferences.debug
    @State private var isInputMonitoringGranted = false
    @State private var isAccessibilityGranted = false

    var body: some View {
        Form {
            Section("한/A 전환") {
                ForEach(rotateKeys, id: \.self) { key in
                    HStack(spacing: 8) {
                        RotateKeyRecorder(rotateKeys: $rotateKeys, key: key)
                        RotateKeyMenu(rotateKeys: $rotateKeys, key: key)
                        removeButton(key)
                    }
                }

                HStack(spacing: 8) {
                    RotateKeyRecorder(rotateKeys: $rotateKeys, key: nil)
                    RotateKeyMenu(rotateKeys: $rotateKeys, key: nil)
                    // 위 줄들과 폭을 맞추기 위한 자리
                    removeButton(nil).hidden()
                }
            }

            Section("기타") {
                Toggle("한글 입력 시 ₩ 대신 ` 입력", isOn: $graveOverWon)
                Toggle("디버그 모드", isOn: $debugMode)
            }

            Section("권한") {
                PermissionRow(title: "입력 모니터링", isGranted: isInputMonitoringGranted, pane: "Privacy_ListenEvent")
                PermissionRow(title: "손쉬운 사용", isGranted: isAccessibilityGranted, pane: "Privacy_Accessibility")
            }
        }
        .formStyle(.grouped)
        .toggleStyle(.switch)
        .scrollDisabled(true)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: rotateKeys) { Preferences.rotateKeys = $0 }
        .onChange(of: graveOverWon) { Preferences.graveOverWon = $0 }
        .onChange(of: debugMode) { Preferences.debug = $0 }
        .onAppear(perform: checkPermissions)
        // 시스템 설정에서 바꾼 권한을 반영
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in checkPermissions() }
    }

    private func removeButton(_ key: RotateKey?) -> some View {
        Button {
            rotateKeys.removeAll { $0 == key }
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
    }

    private func checkPermissions() {
        isInputMonitoringGranted = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        isAccessibilityGranted = AXIsProcessTrusted()
    }
}

/** 권한 허용 여부와 시스템 설정 바로 가기 */
private struct PermissionRow: View {
    let title: String
    let isGranted: Bool
    let pane: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("허용됨")
            } else {
                Text("허용 안 됨")
                    .foregroundStyle(.secondary)
            }

            Button("열기") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(pane)")!
                )
            }
        }
    }
}

// MARK: - 한/A 전환키 입력

/** 클릭 후 누른 키로 한/A 전환키를 바꾸거나 추가, esc로 취소 */
private struct RotateKeyRecorder: View {
    @Binding var rotateKeys: [RotateKey]
    /** 바꿀 키, 없으면 추가 */
    let key: RotateKey?

    @State private var isRecording = false
    @State private var message: String?
    @State private var monitor: Any?
    /** 혼자 눌렀다 떼면 지정할 보조 키 */
    @State private var pendingModifier: Int?

    var body: some View {
        Button {
            isRecording ? stop() : start()
        } label: {
            Text(isRecording ? message ?? "키를 누르세요" : key?.name ?? "키 입력으로 추가")
                .foregroundStyle(isRecording ? Color.accentColor : key == nil ? Color.secondary : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(.quaternary.opacity(isRecording ? 0 : 1), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.accentColor, lineWidth: isRecording ? 2 : 0)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDisappear(perform: stop)
    }

    private func start() {
        isRecording = true
        message = nil
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            record(event)
            return nil
        }
    }

    private func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
        pendingModifier = nil
    }

    private func finish(_ newKey: RotateKey) {
        if newKey == key {
            stop()
        } else if rotateKeys.contains(newKey) {
            message = "이미 추가된 키"
        } else {
            if let key, let index = rotateKeys.firstIndex(of: key) {
                rotateKeys[index] = newKey
            } else {
                rotateKeys.append(newKey)
            }
            stop()
        }
    }

    private func reject() {
        message = "사용할 수 없는 키"
    }

    private func record(_ event: NSEvent) {
        let code = Int(event.keyCode)
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])

        switch event.type {
        case .flagsChanged:
            if code == kVK_CapsLock {
                finish(.shortcut(.capsLock))
            } else if modifiers.isEmpty, pendingModifier == code {
                // 보조 키를 혼자 눌렀다 뗀 경우
                switch code {
                case kVK_RightCommand: finish(.shortcut(.rightCommand))
                case kVK_RightOption: finish(.shortcut(.rightOption))
                default: reject()
                }
            } else {
                pendingModifier = modifiers.isEmpty ? nil : code
            }
        case .keyDown:
            pendingModifier = nil

            if code == kVK_Escape && modifiers.isEmpty {
                stop()
            } else if code == kVK_Space {
                switch modifiers {
                case .command: finish(.shortcut(.commandSpace))
                case .shift: finish(.shortcut(.shiftSpace))
                case .control: finish(.shortcut(.controlSpace))
                default: reject()
                }
            } else if modifiers.isEmpty
                        && QwertyEngine.eventToTuple(event) == nil
                        && ![kVK_Return, kVK_Tab, kVK_Delete].contains(code) {
                // 글자 입력이나 편집에 쓰지 않는 키만 허용
                finish(.keyCode(code))
            } else {
                reject()
            }
        default:
            break
        }
    }
}

// MARK: - 한/A 전환키 직접 설정

/** 분류별 하위 메뉴에서 골라 한/A 전환키를 바꾸거나 추가, 이미 추가된 키는 비활성화 */
private struct RotateKeyMenu: View {
    @Binding var rotateKeys: [RotateKey]
    /** 바꿀 키, 없으면 추가 */
    let key: RotateKey?
    @State private var anchor = RotateKeyMenuAnchor()

    var body: some View {
        Button {
            anchor.popUp(current: key, used: rotateKeys) { newKey in
                if let key, let index = rotateKeys.firstIndex(of: key) {
                    rotateKeys[index] = newKey
                } else {
                    rotateKeys.append(newKey)
                }
            }
        } label: {
            Text("직접 설정")
                .padding(.horizontal, 12)
                .frame(minHeight: 28)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .background(RotateKeyMenuAnchorView(anchor: anchor))
    }
}

/**
 버튼 아래에 띄우는 AppKit 메뉴
 - 입력기 패널에서는 SwiftUI 메뉴 항목이 비활성화되므로 target을 직접 지정
 */
private final class RotateKeyMenuAnchor: NSObject {
    weak var view: NSView?
    private var onSelect: ((RotateKey) -> Void)?

    func popUp(current: RotateKey?, used: [RotateKey], onSelect: @escaping (RotateKey) -> Void) {
        guard let view else { return }

        self.onSelect = onSelect
        let point = NSPoint(x: 0, y: view.isFlipped ? view.bounds.height + 4 : -4)
        makeMenu(current: current, used: used).popUp(positioning: nil, at: point, in: view)
    }

    func makeMenu(current: RotateKey?, used: [RotateKey]) -> NSMenu {
        let menu = NSMenu()

        for category in rotateKeyCategories {
            let submenu = NSMenu()
            submenu.autoenablesItems = false
            for key in category.keys {
                let item = NSMenuItem(title: key.name, action: #selector(select), keyEquivalent: "")
                item.target = self
                item.representedObject = key.rawValue
                item.state = key == current ? .on : .off
                item.isEnabled = key == current || !used.contains(key)
                submenu.addItem(item)
            }

            let item = NSMenuItem(title: category.title, action: nil, keyEquivalent: "")
            item.submenu = submenu
            menu.addItem(item)
        }

        return menu
    }

    @objc private func select(_ item: NSMenuItem) {
        if let rawValue = item.representedObject as? String, let key = RotateKey(rawValue: rawValue) {
            onSelect?(key)
        }
    }
}

private struct RotateKeyMenuAnchorView: NSViewRepresentable {
    let anchor: RotateKeyMenuAnchor

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        anchor.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        anchor.view = nsView
    }
}

private let rotateKeyCategories: [(title: String, keys: [RotateKey])] = [
    ("보조 키", [.shortcut(.capsLock), .shortcut(.rightCommand), .shortcut(.rightOption)]),
    ("조합 키", [.shortcut(.commandSpace), .shortcut(.shiftSpace), .shortcut(.controlSpace)]),
    ("기능 키", [
        kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
        kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20
    ].map { .keyCode($0) }),
    ("기타 키", [
        kVK_Home, kVK_End, kVK_PageUp, kVK_PageDown, kVK_ForwardDelete, kVK_Help, kVK_JIS_Eisu, kVK_JIS_Kana
    ].map { .keyCode($0) })
]

private extension RotateKey {
    var name: String {
        switch self {
        case .shortcut(.capsLock): "한/A (⇪)"
        case .shortcut(.rightCommand): "오른쪽 ⌘"
        case .shortcut(.rightOption): "오른쪽 ⌥"
        case .shortcut(.commandSpace): "⌘스페이스"
        case .shortcut(.shiftSpace): "⇧스페이스"
        case .shortcut(.controlSpace): "⌃스페이스"
        case .keyCode(let code): keyNames[code] ?? "키 코드 \(code)"
        }
    }
}

private let keyNames: [Int: String] = [
    kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5",
    kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
    kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15",
    kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
    kVK_Home: "Home", kVK_End: "End", kVK_PageUp: "Page Up", kVK_PageDown: "Page Down",
    kVK_ForwardDelete: "⌦", kVK_Help: "Help",
    kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
    kVK_JIS_Eisu: "英数", kVK_JIS_Kana: "かな"
]

// MARK: - 정보

private struct AboutSettingsView: View {
    private let version = Bundle.main.releaseVersionNumber ?? "0.0"
    private let build = Bundle.main.buildVersionNumber ?? "0"

    var body: some View {
        HStack(spacing: 24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 6) {
                Text("속 입력기")
                    .font(.headline)
                Text("버전 \(version) (\(build))")
                Text("GPL-3.0 라이선스")
                Link("소스 코드 저장소", destination: URL(string: "https://github.com/kiding/SokIM")!)
                Link("최신 버전", destination: URL(string: "https://github.com/kiding/SokIM/releases")!)
            }
        }
        .padding(32)
        .frame(width: 420)
    }
}
