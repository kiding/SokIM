import InputMethodKit
import Foundation

/** composing이 조합 중인 문자열일 때 selected 기준으로 "조합||커서||블록" 위치 역산 */
private func union(_ selected: NSRange, _ composing: String) -> NSRange {
    let count = composing.utf16.count
    return NSRange(location: max(0, selected.location - count),
                   length: min(NSNotFound, selected.length + count))
}

struct DirectStrategy: Strategy {
    static func backspace(from state: State, to sender: IMKTextInput, with oldState: State) -> Bool {
        debug("\(oldState) -> \(state)")

        // 이전의 "조합||커서||블록" 위치
        let prevRange = union(sender.selectedRange(), oldState.composing)

        // composing이 변경된 경우
        if oldState.composing != state.composing && state.composing.count > 0 {
            sender.insertText(state.composing, replacementRange: prevRange)

            // OS가 추가 처리 하지 않음
            return true
        }
        // 그 외, 초성만 남는 경우도 포함함
        else {
            // OS가 추가 처리함
            return false
        }
    }

    static func insert(from state: State, to sender: IMKTextInput, with oldState: State) {
        debug("\(oldState) -> \(state)")

        // 이전의 "조합||커서||블록" 위치
        let prevRange = union(sender.selectedRange(), oldState.composing)

        // composed -> insertText
        if state.composed.count > 0 {
            // 이전 위치 있으면 -> 대체하여 입력
            if prevRange.length > 0 {
                sender.insertText(state.composed, replacementRange: prevRange)
            }
            // 그 외 -> 기본값 입력
            else {
                sender.insertText(state.composed, replacementRange: defaultRange)
            }
        }

        // composing -> insertText
        if state.composing.count > 0 {
            // 위에서 입력 있었으면 -> 기본값 입력
            if state.composed.count > 0 {
                sender.insertText(state.composing, replacementRange: defaultRange)
            }
            // 위에서 입력 없었는데 이전 위치 있으면 -> 대체하여 입력
            else if prevRange.length > 0 {
                sender.insertText(state.composing, replacementRange: prevRange)
            }
            // 그 외 -> 기본값 입력
            else {
                sender.insertText(state.composing, replacementRange: defaultRange)
            }
        }
    }

    static func flush(from state: State, to sender: IMKTextInput) {
        debug("\(state)")

        // composed -> insertText
        if state.composed.count > 0 {
            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing: 이미 직접 입력되어 있으므로 무시
    }

/*
 상황별 {selectedRange},{markedRange} 변화도
 [이전] > [중간] v [이후(=이전)] > [중간] v ... (단, v: insert, X: {NSNotFound,})

 "ㅎㅏㄴ "
          "ㅎ"            "ㅏ"                "ㄴ"                " "
 Xcode     X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {2,0},X
 <input>
   Safari  X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {2,0},X
   Chrome  X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
   Firefox X,X > {0,0},X v {0,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
 구글 문서
   Safari  X,X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
   Chrome  X,X > {1,0},X v {2,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
   Firefox X,X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
 조합 중단 필요   x
*/
    // 이전과 중간을 비교할 때 사용됨
    static func equal(left: EventContext, right: EventContext) -> Bool {
        debug()

        let doIdentifiersMatch = left.bundleIdentifier == right.bundleIdentifier
        let doPointersMatch = left.pointerValue == right.pointerValue

        let doLocationsDiffByOne = abs(left.selectedRange.location - right.selectedRange.location) <= 1

        // 별도 처리: 메시지 앱에서 여러 줄 입력 시 location 숫자가 급격하게 변함, 무시
        let isMessagesAndNotSelected =
        left.bundleIdentifier == "com.apple.MobileSMS"
        && left.selectedRange.length == 0
        && right.selectedRange.length == 0

        return doIdentifiersMatch
        && doPointersMatch
        && (doLocationsDiffByOne || isMessagesAndNotSelected)
    }
}
