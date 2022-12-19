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
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    private var engine: Engine.Type = TwoSetEngine.self
    private let engines: [Engine.Type] = [QwertyEngine.self, TwoSetEngine.self]

    /** 메뉴 */

    private let menu = NSMenu()

    /** 시스템 메시지 */

    private let messageItem = NSMenuItem()

    /** 한/A 전환키 */

    private let capsLockItem = NSMenuItem()
    private let commandSpaceItem = NSMenuItem()
    private let shiftSpaceItem = NSMenuItem()
    private let controlSpaceItem = NSMenuItem()

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

        messageItem.title = "초기화 중..."
        menu.addItem(messageItem)

        menu.addItem(NSMenuItem.separator())

        /** 한/A 전환키 */

        let rotateShortcutItem = NSMenuItem()
        rotateShortcutItem.title = "한/A 전환"
        menu.addItem(rotateShortcutItem)

        capsLockItem.title = "한/A (⇪)"
        capsLockItem.state = Preferences.rotateShortcut == .capsLock ? .on : .off
        capsLockItem.target = self
        capsLockItem.action = #selector(toggleCapsLock)
        menu.addItem(capsLockItem)

        commandSpaceItem.title = "⌘스페이스"
        commandSpaceItem.state = Preferences.rotateShortcut == .commandSpace ? .on : .off
        commandSpaceItem.target = self
        commandSpaceItem.action = #selector(toggleCommandSpace)
        menu.addItem(commandSpaceItem)

        shiftSpaceItem.title = "⇧스페이스"
        shiftSpaceItem.state = Preferences.rotateShortcut == .shiftSpace ? .on : .off
        shiftSpaceItem.target = self
        shiftSpaceItem.action = #selector(toggleShiftSpace)
        menu.addItem(shiftSpaceItem)

        controlSpaceItem.title = "⌃스페이스"
        controlSpaceItem.state = Preferences.rotateShortcut == .controlSpace ? .on : .off
        controlSpaceItem.target = self
        controlSpaceItem.action = #selector(toggleControlSpace)
        menu.addItem(controlSpaceItem)

        menu.addItem(NSMenuItem.separator())

        /** 기타 설정 */

        let graveItem = NSMenuItem()
        graveItem.title = "₩ 대신 ` 입력"
        graveItem.state = Preferences.graveOverWon ? .on : .off
        graveItem.target = self
        graveItem.action = #selector(toggleGraveOverWon)
        menu.addItem(graveItem)

        let debugItem = NSMenuItem()
        debugItem.title = "디버그 모드"
        debugItem.state = Preferences.debug ? .on : .off
        debugItem.target = self
        debugItem.action = #selector(toggleDebug)
        menu.addItem(debugItem)
    }

    /** 한/A 상태 */

    func rotateEngine() {
        debug()

        let count = engines.count
        let index = engines.firstIndex(where: { $0 == engine }) ?? 0
        engine = engines[(index + 1) % count]

        statusItem.button?.title = engine.name
    }

    func setEngine(_ engine: Engine.Type) {
        debug()

        self.engine = engine
        statusItem.button?.title = engine.name
    }

    func setStatus(_ msg: String) {
        debug()

        statusItem.button?.title = msg
    }

    /** 시스템 메시지 */

    func setMessage(_ msg: String) {
        debug()

        messageItem.title = msg
    }

    func removeMessage() {
        debug()

        menu.removeItem(messageItem)
    }

    /** 한/A 전환키 */

    @objc func toggleCapsLock(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .capsLock
            capsLockItem.state = .on
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleCommandSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .commandSpace
            capsLockItem.state = .off
            commandSpaceItem.state = .on
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleShiftSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .shiftSpace
            capsLockItem.state = .off
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .on
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleControlSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .controlSpace
            capsLockItem.state = .off
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .on
        }
    }

    /** 기타 설정 */

    @objc func toggleDebug(sender: NSMenuItem) {
        Preferences.debug = sender.state == .on ? false : true
        sender.state = Preferences.debug ? .on : .off
    }

    @objc func toggleGraveOverWon(sender: NSMenuItem) {
        Preferences.graveOverWon = sender.state == .on ? false : true
        sender.state = Preferences.graveOverWon ? .on : .off
    }
}
