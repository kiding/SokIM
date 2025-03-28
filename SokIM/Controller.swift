import InputMethodKit

/**
 @see Info.plist
 */
@objc(Controller)
class Controller: IMKInputController {
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        debug("\(String(describing: event)) \(String(describing: sender))")

        return AppDelegate.shared().handle(event, client: sender)
    }
}
