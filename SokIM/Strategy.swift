import InputMethodKit

/**
 입력 방식 선택

 # `sender.validAttributesForMarkedText()`

 ## Direct

 | App | Attributes |
 |--|--|
 | Xcode | NSMarkedClauseSegment NSGlyphInfo ... |
 | Pages | ... NSFont NSMarkedClauseSegment ... |
 | Numbers | ... NSFont NSMarkedClauseSegment ... |
 | Keynote | ... NSFont NSMarkedClauseSegment ... |
 | Word | NSFont ... NSMarkedClauseSegment ... |
 | PowerPoint | NSFont ... NSMarkedClauseSegment ... |
 | TextEdit | NSFont ... NSMarkedClauseSegment ... NSGlyphInfo NSTextAlternatives ... |
 | Stickies | NSFont ... NSMarkedClauseSegment ... NSGlyphInfo NSTextAlternatives ... |
 | Tweetbot | NSFont ... NSMarkedClauseSegment ... NSTextAlternatives ... |
 | Paw | NSFont ... NSMarkedClauseSegment ... NSTextAlternatives ... |
 | Safari | ... NSMarkedClauseSegment NSTextAlternatives ... |
 | DuckDuckGo | ... NSMarkedClauseSegment NSTextAlternatives ... |
 | Overcast | ... NSMarkedClauseSegment NSTextAlternatives ... |

 ## Marked

 | App | Attributes |
 |--|--|
 | GIMP | ... |
 | Sublime Text | ... |
 | Alacritty | ... |
 | Android Studio | ... |
 | iTerm2 | ... NSFont ... |
 | Terminal | ... |
 | LINE | ... |
 | VS Code | ... NSMarkedClauseSegment ... |
 | Chrome | ... NSMarkedClauseSegment ... |
 | Firefox | ... NSMarkedClauseSegment ... |
 | Slack | ... NSMarkedClauseSegment ... |
 | Excel | ... |
 */
func strategy(for sender: IMKTextInput) -> Strategy.Type {
    let attributes = sender.validAttributesForMarkedText() as? [String] ?? []
    debug("validAttributesForMarkedText: \(attributes)")

    if attributes.contains("NSTextAlternatives")
        || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSFont")
        || attributes.contains("NSMarkedClauseSegment") && attributes.contains("NSGlyphInfo") {
        return DirectStrategy.self
    } else {
        return MarkedStrategy.self
    }
}

/** 입력 방식 */
protocol Strategy {
    /** 백스페이스 처리된 state를 sender에 입력. 완료 후 sender가 추가 처리해야 하면 false, 필요하지 않으면 true 반환 */
    static func backspace(from state: State, to sender: IMKTextInput, with oldState: State) -> Bool

    /** 조합 지속을 목적으로 state에 저장된 문자열을 sender에 입력 */
    static func next(from state: State, to sender: IMKTextInput, with oldState: State)

    /** 조합 종료를 목적으로 state에 저장된 문자열을 sender에 입력 */
    static func commit(from state: State, to sender: IMKTextInput)
}
