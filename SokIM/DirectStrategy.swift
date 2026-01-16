import InputMethodKit
import Foundation

/** composing이 조합 중인 문자열일 때 selected 기준으로 "조합||커서" 또는 "조합||커서||블록" 위치 역산 */
private func range(_ selected: NSRange, _ composing: String, includeBlock: Bool) -> NSRange {
    let count = composing.utf16.count
    let location = selected.location - count
    let block = includeBlock ? selected.length : 0

    return location >= 0
    ? NSRange(location: location, length: count + block)
    : NSRange(location: 0, length: location + count + block)
}

struct DirectStrategy: Strategy {
    static func backspace(from state: State, to sender: IMKTextInput, with composing: String) -> Bool {
        debug("\(composing) -> \(state)")

        // 이전 조합 문자열 확인
        let selected = sender.selectedRange()
        var prevRange = range(selected, composing, includeBlock: false) // "조합||커서"
        let prevString = sender.string(from: prevRange, actualRange: &prevRange) ?? ""
        prevRange = range(selected, composing, includeBlock: true) // "조합||커서||블록"

        // 그 사이에 이전 조합이 달라진 경우
        if prevString != composing {
            // OS가 추가 처리함
            debug("return false")
            return false
        }
        // composing이 변경된 경우
        else if composing != state.composing && state.composing.count > 0 {
            sender.insertText(state.composing, replacementRange: prevRange)

            // OS가 추가 처리 하지 않음
            debug("return true")
            return true
        }
        // 그 외, 초성만 남는 경우도 포함함
        else {
            // OS가 추가 처리함
            debug("return false")
            return false
        }
    }

    static func next(from state: State, to sender: IMKTextInput, with composing: String) -> Bool {
        debug("\(composing) -> \(state)")

        // 이전 조합 문자열 확인
        let selected = sender.selectedRange()
        var prevRange = range(selected, composing, includeBlock: false) // "조합||커서"
        let prevString = sender.string(from: prevRange, actualRange: &prevRange) ?? ""
        prevRange = range(selected, composing, includeBlock: true) // "조합||커서||블록"

        // 그 사이에 이전 조합이 달라진 경우
        if prevString != composing {
            // 입력 실패
            debug("return false")
            return false
        }

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

        debug("return true")
        return true
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
