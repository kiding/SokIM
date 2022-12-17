import InputMethodKit

struct MarkedStrategy: Strategy {
    static func backspace(from state: State, to sender: IMKTextInput, with oldState: State) -> Bool {
        debug("\(oldState) -> \(state)")

        // composing이 변경된 경우
        if oldState.composing != state.composing {
            sender.setMarkedText(state.composing, selectionRange: defaultRange, replacementRange: defaultRange)

            // OS가 추가 처리 하지 않음
            return true
        } else {
            // OS가 추가 처리함
            return false
        }
    }

    static func insert(from state: State, to sender: IMKTextInput, with oldState: State) {
        debug("\(oldState) -> \(state)")

        // composed -> insertText
        if state.composed.count > 0 {
            /*
             블록 선택 상태일 때 미리 setMarkedText를 하지 않으면 오작동하는 상황 처리
             예시: "asdf" -> ⌘A -> "asdf" 입력 -> "sdf" (Safari에서 작동하는 구글 문서 등)
             */
            let selectedRange = sender.selectedRange()
            if 0 < selectedRange.length && selectedRange.length < NSNotFound {
                sender.setMarkedText(state.composed, selectionRange: defaultRange, replacementRange: selectedRange)
            }

            sender.insertText(state.composed, replacementRange: defaultRange)
        }

        // composing -> setMarkedText
        if state.composing.count > 0 {
            sender.setMarkedText(state.composing, selectionRange: defaultRange, replacementRange: defaultRange)
        }
    }

    static func flush(from state: State, to sender: IMKTextInput) {
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

/*
 상황별 {selectedRange},{markedRange} 변화도
 [이전] > [중간] v [이후(=이전)] > [중간] v ... (단, v: insert, X: {NSNotFound,})

 1. "ㅎㅏㄴ "
          "ㅎ"            "ㅏ"                         "ㄴ"                         " "
 Xcode     X,X > {0,0},X v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {2,0},X
 <input>
   Safari  X,X > {0,0},X v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {2,0},X
   Chrome  X,X > {0,0},X v {0,0},{0,1} > {0,0},{0,1} v {0,0},{0,1} > {0,0},{0,1} v {0,0},{0,1} > {0,0},{0,1} v {2,0},X
   Firefox X,X > {0,0},X v {0,1},{0,1} > {1,0},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {0,1},{0,1} v {2,0},X
 구글 문서
   Safari  X,X > {1,0},X v {1,1},{1,1} > {1,1},{1,1} v {1,1},{1,1} > {1,1},{1,1} v {1,1},{1,1} > {1,1},{1,1} v {1,0},X
   Chrome  X,X > {1,0},X v {1,0},{1,1} > {1,0},{1,1} v {1,0},{1,1} > {1,0},{1,1} v {1,0},{1,1} > {1,0},{1,1} v {3,0},X
   Firefox X,X > {1,0},X v {1,1},{1,1} > {2,0},{1,1} v {1,1},{1,1} > {1,1},{1,1} v {1,1},{1,1} > {1,1},{1,1} v {3,0},X
 조합 중단 필요   x

 2. "ㅎㅏ" 마우스로 다른 영역 선택 "ㄴ"
          "ㅎ"            "ㅏ"                         마우스 "ㄴ"
 Xcode     X,X > {0,0},X v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {7,0},{0,1} v {7,1},{0,1}
 <textarea>
   Safari  X,X > {0,0},X v {0,1},{0,1} > {0,1},{0,1} v {0,1},{0,1} > {7,0},X     v {7,1},{7,1}
   Chrome  X,X > {0,0},X v {0,0},{0,1} > {0,0},{0,1} v {0,0},{0,1} > {7,0},{0,1} v {7,0},{0,1}
   Firefox X,X > {0,0},X v {0,1},{0,1} > {1,0},{0,1} v {0,1},{0,1} (조합 중에 마우스로 커서 이동 불가)
 구글 문서
   Safari  X,X > {1,0},X v {1,1},{1,1} > {1,1},{1,1} v {1,1},{1,1} > {1,1},X     v {1,1},{1,1}
   Chrome  X,X > {1,0},X v {1,0},{1,1} > {1,0},{1,1} v {1,0},{1,1} > {1,0},{1,1} v {1,0},{1,1}
   Firefox X,X > {1,0},X v {1,1},{1,1} > {2,0},{1,1} v {1,1},{1,1} (조합 중에 마우스로 커서 이동 불가)
 조합 중단 필요   x                                                   x
*/
    // 이전과 중간을 비교할 때 사용됨
    static func equal(left: EventContext, right: EventContext) -> Bool {
        debug()

        let doIdentifiersMatch = left.bundleIdentifier == right.bundleIdentifier

        let doPointersMatch = left.pointerValue == right.pointerValue

        let doMarkedsNotExistAndSelectedsMatch =
        left.markedRange.location == NSNotFound
        && right.markedRange.location == NSNotFound
        && left.selectedRange == right.selectedRange

        let doMarkedsExistAndMatchAndIncluded =
        left.markedRange.location != NSNotFound
        && right.markedRange.location != NSNotFound
        && left.markedRange == right.markedRange
        && abs((left.selectedRange.location + left.selectedRange.length)
               - (right.selectedRange.location + right.selectedRange.length))
        <= left.markedRange.length * 2 // 2칸씩 이동하는 경우 있음 (예: 터미널)

        // 특수 처리: Slack 앱에서 빠르게 입력하는 경우 조합 도중에 selectedRange가 0이 되는 경우 있음
        let doMarkedExistAndSelectedIsZero =
        left.markedRange.location != NSNotFound
        && right.markedRange.location != NSNotFound
        && left.markedRange == right.markedRange
        && (left.selectedRange == NSRange(location: 0, length: 0)
            || right.selectedRange == NSRange(location: 0, length: 0))

        return doIdentifiersMatch
        && doPointersMatch
        && (doMarkedsNotExistAndSelectedsMatch
            || doMarkedsExistAndMatchAndIncluded
            || doMarkedExistAndSelectedIsZero)
    }
}
