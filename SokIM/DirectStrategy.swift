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

    static func next(from state: State, to sender: IMKTextInput, with oldState: State) {
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

    static func commit(from state: State, to sender: IMKTextInput) {
        debug("\(state)")

        // composed -> insertText
        if state.composed.count > 0 {
            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing: 이미 직접 입력되어 있으므로 무시
    }
}
