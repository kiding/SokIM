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
    private let engines = (한: TwoSetEngine.self, A: QwertyEngine.self)

    /** 메뉴 */

    private let menu = NSMenu()

    /** 시스템 메시지 */

    private let messageItem = NSMenuItem()

    /** 한/A 전환키 */

    private let capsLockItem = NSMenuItem()
    private let rightCommandItem = NSMenuItem()
    private let commandSpaceItem = NSMenuItem()
    private let shiftSpaceItem = NSMenuItem()
    private let controlSpaceItem = NSMenuItem()

    // swiftlint:disable:next function_body_length
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

        /** 업데이트 확인 */

        let updateItem = NSMenuItem()
        updateItem.title = "업데이트 확인..."
        updateItem.target = self
        updateItem.action = #selector(checkUpdate)
        menu.addItem(updateItem)

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

        rightCommandItem.title = "오른쪽 ⌘"
        rightCommandItem.state = Preferences.rotateShortcut == .rightCommand ? .on : .off
        rightCommandItem.target = self
        rightCommandItem.action = #selector(toggleRightCommand)
        menu.addItem(rightCommandItem)

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

        let abcItem = NSMenuItem()
        abcItem.title = "ABC 입력기 제한"
        abcItem.state = Preferences.suppressABC ? .on : .off
        abcItem.target = self
        abcItem.action = #selector(toggleSuppressABC)
        menu.addItem(abcItem)

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

        engine = engine == engines.한 ? engines.A : engines.한
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

    /** 업데이트 확인 */

    @objc func checkUpdate(sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://github.com/kiding/SokIM")!)
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
            rightCommandItem.state = .off
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleRightCommand(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .rightCommand
            capsLockItem.state = .off
            rightCommandItem.state = .on
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleCommandSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .commandSpace
            capsLockItem.state = .off
            rightCommandItem.state = .off
            commandSpaceItem.state = .on
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleShiftSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .shiftSpace
            capsLockItem.state = .off
            rightCommandItem.state = .off
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .on
            controlSpaceItem.state = .off
        }
    }

    @objc func toggleControlSpace(sender: NSMenuItem) {
        if sender.state == .off {
            Preferences.rotateShortcut = .controlSpace
            capsLockItem.state = .off
            rightCommandItem.state = .off
            commandSpaceItem.state = .off
            shiftSpaceItem.state = .off
            controlSpaceItem.state = .on
        }
    }

    /** 기타 설정 */

    @objc func toggleGraveOverWon(sender: NSMenuItem) {
        Preferences.graveOverWon = sender.state == .on ? false : true
        sender.state = Preferences.graveOverWon ? .on : .off
    }

    @objc func toggleSuppressABC(sender: NSMenuItem) {
        Preferences.suppressABC = sender.state == .on ? false : true
        sender.state = Preferences.suppressABC ? .on : .off
    }

    @objc func toggleDebug(sender: NSMenuItem) {
        Preferences.debug = sender.state == .on ? false : true
        sender.state = Preferences.debug ? .on : .off
    }
}
