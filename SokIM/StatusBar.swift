import AppKit

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

class StatusBar {
    private var engine: Engine.Type = TwoSetEngine.self
    private let engines = (한: TwoSetEngine.self, A: QwertyEngine.self)

    /** 메뉴 */

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    /** 시스템 메시지 */

    private let errorItem = NSMenuItem()
    private let noticeItem = NSMenuItem()

    /** 설정 창 */

    private var settingsPanel: NSPanel?

    init() {
        debug()

        /** 한/A 상태 */

        statusItem.button?.title = "⌨️"
        statusItem.menu = menu

        /** 입력기 정보 */

        let version = Bundle.main.releaseVersionNumber ?? "0.0"
        let build = Bundle.main.buildVersionNumber ?? "0"
        let infoItem = NSMenuItem()
        infoItem.title = "속 입력기 v\(version) (\(build))"
        menu.addItem(infoItem)

        /** 시스템 메시지 */

        errorItem.title = ""
        errorItem.isHidden = true
        menu.addItem(errorItem)

        noticeItem.title = ""
        noticeItem.isHidden = true
        menu.addItem(noticeItem)

        /** 업데이트 확인 */

        let updateItem = NSMenuItem()
        updateItem.title = "업데이트 확인..."
        updateItem.target = self
        updateItem.action = #selector(checkUpdate)
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        /** 설정 */

        let settingsItem = NSMenuItem()
        settingsItem.title = "설정..."
        settingsItem.target = self
        settingsItem.action = #selector(openSettings)
        menu.addItem(settingsItem)
    }

    /** 한/A 상태 */

    func rotateEngine() {
        debug()

        engine = engine == engines.한 ? engines.A : engines.한
        statusItem.button?.title = engine.name
    }

    func setEngine(_ engine: Engine.Type) {
        debug("\(engine)")

        self.engine = engine
        statusItem.button?.title = engine.name
    }

    func setStatus(_ msg: String) {
        debug("\(msg)")

        statusItem.button?.title = msg
    }

    /** 업데이트 확인 */

    @objc func checkUpdate(sender: NSMenuItem?) {
        debug()

        NSWorkspace.shared.open(URL(string: "https://github.com/kiding/SokIM/releases")!)
    }

    /** 시스템 메시지 */

    func setError(_ msg: String?) {
        debug()

        if let msg {
            errorItem.title = msg
            errorItem.isHidden = false
        } else {
            errorItem.isHidden = true
            errorItem.title = ""
        }
    }

    func setNotice(_ msg: String?) {
        debug()

        if let msg {
            noticeItem.title = msg
            noticeItem.isHidden = false
        } else {
            noticeItem.isHidden = true
            noticeItem.title = ""
        }
    }

    /** 설정 창 */

    @objc func openSettings(sender: NSMenuItem) {
        debug()

        // 활성화 없이도 입력을 받는 패널 사용
        let panel = settingsPanel ?? NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        if settingsPanel == nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(settingsWillClose),
                name: NSWindow.willCloseNotification,
                object: panel
            )
        }
        panel.toolbarStyle = .preference
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentViewController = makeSettingsViewController()
        panel.center()
        settingsPanel = panel

        // 비활성 창은 스위치 등이 회색으로 그려지므로 설정 창을 여는 동안만 활성화 가능하게 변경
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func settingsWillClose(_ notification: Notification) {
        debug()

        NSApp.setActivationPolicy(.prohibited)
    }
}
