import InputMethodKit
import Foundation

/** composing이 조합 중인 문자열일 때 selected 기준으로 "조합||커서||블록" 위치 역산 */
private func union(_ selected: NSRange, _ composing: String) -> NSRange {
    let count = composing.utf16.count
    return NSRange(location: max(0, selected.location - count),
                   length: min(NSNotFound, selected.length + count))
}

struct DirectStrategy: Strategy {
    static func backspace(with state: inout State, to sender: IMKTextInput) -> Bool {
        debug()

        // 이전의 "조합||커서||블록" 위치
        let prevRange = union(sender.selectedRange(), state.composing)

        // 이전에 조합 중이던 글자에서 백스페이스
        if state.deleteBackwardComposing() && state.composing.count > 0 {
            // 변경된 경우 composing으로 갱신
            sender.insertText(state.composing, replacementRange: prevRange)
            state.clear(includeComposing: false)

            // sender가 추가 처리 하지 않음
            return true
        }
        // 그 외, 초성만 남는 경우도 포함함
        else {
            // 완성/조합/입력 초기화
            state.clear(includeComposing: true)

            // sender가 처리함
            return false
        }
    }

    static func tuples(_ tuples: [CharTuple], with state: inout State, to sender: IMKTextInput) {
        debug("\(tuples)")
        if tuples.count <= 0 { return }

        // 이전의 "조합||커서||블록" 위치
        let prevRange = union(sender.selectedRange(), state.composing)

        // tuples 처리
        tuples.forEach { state.next($0) }

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

        // 완성/입력 초기화
        state.clear(includeComposing: false)
    }

    static func flush(with state: inout State, to sender: IMKTextInput) {
        debug()

        // composed -> insertText
        if state.composed.count > 0 {
            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing: 이미 직접 입력되어 있으므로 무시

        // 완성/조합/입력 초기화
        state.clear(includeComposing: true)
    }

/*
 상황별 {selectedRange},{markedRange} 변화도
 [이전] > [중간] v [이후(=이전)] > [중간] v ... (단, v: insert, X: {NSNotFound,})

 1. "ㅎㅏㄴ "
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

 2. "ㅎㅏ" 마우스로 다른 영역 선택 "ㄴ"
          "ㅎ"            "ㅏ"                마우스 "ㄴ"
 Xcode     X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {7,0},X v {7,0},X
 <textarea>
   Safari  X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {7,0},X v {7,0},X
   Chrome  X,X > {0,0},X v {1,0},X > {1,0},X v {1,0},X > {7,0},X v {7,0},X
   Firefox X,X > {0,0},X v {0,0},X > {1,0},X v {1,0},X > {7,0},X v {7,0},X
 구글 문서
   Safari  X,X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
   Chrome  X,X > {1,0},X v {2,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
   Firefox X,X > {1,0},X v {1,0},X > {1,0},X v {1,0},X > {1,0},X v {1,0},X
 조합 중단 필요   x                                        x
*/
    static func equal(left: EventContext, right: EventContext) -> Bool {
        debug()

        let doIdentifiersMatch = left.bundleIdentifier == right.bundleIdentifier
        let doPointersMatch = left.pointerValue == right.pointerValue
        let doLocationsDiffByOne = abs(left.selectedRange.location - right.selectedRange.location) <= 1
        let doLengthsMatch = left.selectedRange.length == right.selectedRange.length

        return doIdentifiersMatch && doPointersMatch && doLocationsDiffByOne && doLengthsMatch
    }
}
