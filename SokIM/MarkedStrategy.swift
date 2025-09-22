import InputMethodKit

struct MarkedStrategy: Strategy {
    static func backspace(from state: State, to sender: IMKTextInput, with oldState: State) -> Bool {
        debug("\(oldState) -> \(state)")

        // composing이 변경된 경우
        if oldState.composing != state.composing {
            let string = NSAttributedString(string: state.composing, attributes: [.backgroundColor: NSColor.clear])
            sender.setMarkedText(string, selectionRange: defaultRange, replacementRange: defaultRange)

            // OS가 추가 처리 하지 않음
            return true
        } else {
            // OS가 추가 처리함
            return false
        }
    }

    static func next(from state: State, to sender: IMKTextInput, with oldState: State) {
        debug("\(oldState) -> \(state)")

        // composed -> insertText
        if state.composed.count > 0 {
            /*
             블록 선택 상태일 때 미리 setMarkedText를 하지 않으면 오작동하는 상황 처리
             예시: "asdf" -> ⌘A -> "asdf" 입력 -> "sdf" (Safari에서 작동하는 구글 문서 등)
             */
            let selectedRange = sender.selectedRange()
            if 0 < selectedRange.length && selectedRange.length < NSNotFound {
                let string = NSAttributedString(string: state.composed, attributes: [.backgroundColor: NSColor.clear])
                sender.setMarkedText(string, selectionRange: defaultRange, replacementRange: selectedRange)
            }

            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing -> setMarkedText
        if state.composing.count > 0 {
            let string = NSAttributedString(string: state.composing, attributes: [.backgroundColor: NSColor.clear])
            sender.setMarkedText(string, selectionRange: defaultRange, replacementRange: defaultRange)
        }
    }

    static func commit(from state: State, to sender: IMKTextInput) {
        debug("\(state)")

        // composed -> insertText
        if state.composed.count > 0 {
            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing -> insertText
        if state.composing.count > 0 {
            sender.insertText(state.composing, replacementRange: defaultRange)
        }
    }
}
