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

    /** 한/A 전환키 */

    private let capsLockItem = NSMenuItem()
    private let rightCommandItem = NSMenuItem()
    private let rightOptionItem = NSMenuItem()
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

        /** 한/A 전환키 */

        let rotateShortcutItem = NSMenuItem()
        rotateShortcutItem.title = "한/A 전환"
        menu.addItem(rotateShortcutItem)

        capsLockItem.title = "한/A (⇪)"
        capsLockItem.state = Preferences.rotateShortcuts.contains(.capsLock) ? .on : .off
        capsLockItem.target = self
        capsLockItem.action = #selector(toggleCapsLock)
        menu.addItem(capsLockItem)

        rightCommandItem.title = "오른쪽 ⌘"
        rightCommandItem.state = Preferences.rotateShortcuts.contains(.rightCommand) ? .on : .off
        rightCommandItem.target = self
        rightCommandItem.action = #selector(toggleRightCommand)
        menu.addItem(rightCommandItem)

        rightOptionItem.title = "오른쪽 ⌥"
        rightOptionItem.state = Preferences.rotateShortcuts.contains(.rightOption) ? .on : .off
        rightOptionItem.target = self
        rightOptionItem.action = #selector(toggleRightOption)
        menu.addItem(rightOptionItem)

        commandSpaceItem.title = "⌘스페이스"
        commandSpaceItem.state = Preferences.rotateShortcuts.contains(.commandSpace) ? .on : .off
        commandSpaceItem.target = self
        commandSpaceItem.action = #selector(toggleCommandSpace)
        menu.addItem(commandSpaceItem)

        shiftSpaceItem.title = "⇧스페이스"
        shiftSpaceItem.state = Preferences.rotateShortcuts.contains(.shiftSpace) ? .on : .off
        shiftSpaceItem.target = self
        shiftSpaceItem.action = #selector(toggleShiftSpace)
        menu.addItem(shiftSpaceItem)

        controlSpaceItem.title = "⌃스페이스"
        controlSpaceItem.state = Preferences.rotateShortcuts.contains(.controlSpace) ? .on : .off
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
        debug("\(engine)")

        self.engine = engine
        statusItem.button?.title = engine.name
    }

    func setStatus(_ msg: String) {
        debug("\(msg)")

        statusItem.button?.title = msg
    }

    /** 업데이트 확인 */

    @objc func checkUpdate(sender: NSMenuItem) {
        debug()

        NSWorkspace.shared.open(URL(string: "https://github.com/kiding/SokIM")!)
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

    /** 한/A 전환키 */

    @objc func toggleCapsLock(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.capsLock)
            capsLockItem.state = .on
        } else {
            rotateShortcuts.remove(.capsLock)
            capsLockItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
    }

    @objc func toggleRightCommand(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.rightCommand)
            rightCommandItem.state = .on
        } else {
            rotateShortcuts.remove(.rightCommand)
            rightCommandItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
    }

    @objc func toggleRightOption(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.rightOption)
            rightOptionItem.state = .on
        } else {
            rotateShortcuts.remove(.rightOption)
            rightOptionItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
    }

    @objc func toggleCommandSpace(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.commandSpace)
            commandSpaceItem.state = .on
        } else {
            rotateShortcuts.remove(.commandSpace)
            commandSpaceItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
    }

    @objc func toggleShiftSpace(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.shiftSpace)
            shiftSpaceItem.state = .on
        } else {
            rotateShortcuts.remove(.shiftSpace)
            shiftSpaceItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
   }

    @objc func toggleControlSpace(sender: NSMenuItem) {
        debug()

        var rotateShortcuts = Preferences.rotateShortcuts
        if sender.state == .off {
            rotateShortcuts.insert(.controlSpace)
            controlSpaceItem.state = .on
        } else {
            rotateShortcuts.remove(.controlSpace)
            controlSpaceItem.state = .off
        }
        Preferences.rotateShortcuts = rotateShortcuts

        statusItem.button?.performClick(nil)
   }

    /** 기타 설정 */

    @objc func toggleGraveOverWon(sender: NSMenuItem) {
        debug()

        Preferences.graveOverWon = sender.state == .on ? false : true
        sender.state = Preferences.graveOverWon ? .on : .off
    }

    @objc func toggleSuppressABC(sender: NSMenuItem) {
        debug()

        Preferences.suppressABC = sender.state == .on ? false : true
        sender.state = Preferences.suppressABC ? .on : .off
    }

    @objc func toggleDebug(sender: NSMenuItem) {
        debug()

        Preferences.debug = sender.state == .on ? false : true
        sender.state = Preferences.debug ? .on : .off
    }
}
