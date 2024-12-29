import InputMethodKit

/**
 @see Info.plist
 */
@objc(Controller)
class Controller: IMKInputController {
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        (NSApp.delegate as! AppDelegate).handle(event, client: sender)
    }
}
