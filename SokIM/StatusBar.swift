import AppKit

class StatusBar {
    private let statusItem: NSStatusItem

    private var engine: Engine.Type = TwoSetEngine.self
    private let engines: [Engine.Type] = [QwertyEngine.self, TwoSetEngine.self]

    private let menu: NSMenu
    private let appNameItem: NSMenuItem
    private let messageItem: NSMenuItem
    private let separatorItem: NSMenuItem

    init() {
        debug()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = "⌨️"

        menu = NSMenu.init(title: "SokIM")
        statusItem.menu = menu

        appNameItem = NSMenuItem.init()
        appNameItem.title = "속 입력기"
        menu.addItem(appNameItem)

        messageItem = NSMenuItem.init()
        messageItem.title = "초기화 중..."
        menu.addItem(messageItem)

        separatorItem = NSMenuItem.separator()
        menu.addItem(separatorItem)

        let graveItem = NSMenuItem.init()
        graveItem.title = "₩ 대신 ` 입력"
        graveItem.state = Preferences.graveOverWon ? .on : .off
        graveItem.target = self
        graveItem.action = #selector(toggleGraveOverWon)
        menu.addItem(graveItem)

        let debugItem = NSMenuItem.init()
        debugItem.title = "디버그 모드"
        debugItem.state = Preferences.debug ? .on : .off
        debugItem.target = self
        debugItem.action = #selector(toggleDebug)
        menu.addItem(debugItem)
    }

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

    func setMessage(_ msg: String) {
        debug()

        messageItem.title = msg
    }

    func removeMessage() {
        debug()

        menu.removeItem(messageItem)
        menu.removeItem(separatorItem)
    }

    @objc func toggleDebug(sender: NSMenuItem) {
        Preferences.debug = sender.state == .on ? false : true
        sender.state = Preferences.debug ? .on : .off
    }

    @objc func toggleGraveOverWon(sender: NSMenuItem) {
        Preferences.graveOverWon = sender.state == .on ? false : true
        sender.state = Preferences.graveOverWon ? .on : .off
    }
}
