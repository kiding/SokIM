import InputMethodKit

/** 키보드 입력 후 InputMethodKit에 의해 event 발생 시점의 context */
struct EventContext {
    /** AppDelegate.handle로 들어오는 sender */
    let sender: IMKTextInput?
    /** 입력되는 앱, sender 상황에 따라 달라짐 */
    let bundleIdentifier: String
    /** 포인터 값, sender 상황에 따라 달라짐 */
    let pointerValue: Int
    /** 현재 selectedRange(커서) 정보 */
    let selectedRange: NSRange
    /** 현재 markedRange(밑줄) 정보 */
    let markedRange: NSRange
    /** 입력 방식: 직접 / 밑줄 */
    let strategy: Strategy.Type

    init() {
        debug()

        sender = nil
        bundleIdentifier = ""
        pointerValue = 0
        selectedRange = defaultRange
        markedRange = defaultRange
        strategy = MarkedStrategy.self
    }

    init(_ sender: IMKTextInput) {
        debug()

        self.sender = sender
        bundleIdentifier = sender.bundleIdentifier()
        pointerValue = Unmanaged<AnyObject>.passUnretained(sender).toOpaque().hashValue
        selectedRange = sender.selectedRange()
        markedRange = sender.markedRange()

/*
 # 입력 방식 선택: sender.validAttributesForMarkedText() 휴리스틱

 ## Direct

 Xcode          NSMarkedClauseSegment NSGlyphInfo ...
 Pages          ... NSFont NSMarkedClauseSegment ...
 Numbers        ... NSFont NSMarkedClauseSegment ...
 Keynote        ... NSFont NSMarkedClauseSegment ...
 Word           NSFont ... NSMarkedClauseSegment ...
 PowerPoint     NSFont ... NSMarkedClauseSegment ...
 TextEdit       NSFont ... NSMarkedClauseSegment ... NSGlyphInfo NSTextAlternatives ...
 Stickies       NSFont ... NSMarkedClauseSegment ... NSGlyphInfo NSTextAlternatives ...
 Tweetbot       NSFont ... NSMarkedClauseSegment ... NSTextAlternatives ...
 Paw            NSFont ... NSMarkedClauseSegment ... NSTextAlternatives ...
 Safari         ... NSMarkedClauseSegment NSTextAlternatives ...
 DuckDuckGo     ... NSMarkedClauseSegment NSTextAlternatives ...
 Overcast       ... NSMarkedClauseSegment NSTextAlternatives ...

 ## Marked

 GIMP           ...
 Sublime Text   ...
 Alacritty      ...
 Android Studio ...
 iTerm2         ... NSFont ...
 Terminal       ...
 LINE           ...
 VS Code        ... NSMarkedClauseSegment ...
 Chrome         ... NSMarkedClauseSegment ...
 Firefox        ... NSMarkedClauseSegment ...
 Slack          ... NSMarkedClauseSegment ...
 Excel          ...
 */
        let attributes = sender.validAttributesForMarkedText() as? [String] ?? []
        debug("validAttributesForMarkedText: \(attributes)")

        if attributes.contains("NSTextAlternatives")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSFont")
            || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSGlyphInfo") {
            strategy = DirectStrategy.self
        } else {
            strategy = MarkedStrategy.self
        }
    }

    static func == (left: Self, right: Self) -> Bool {
        debug("\(left) \(right)")

        return left.strategy == right.strategy
        ? left.strategy.equal(left: left, right: right)
        : false
    }

    static func != (left: Self, right: Self) -> Bool {
        debug("\(left) \(right)")

        return !(left == right)
    }
}
