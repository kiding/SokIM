import InputMethodKit

/** 입력 방식 */
protocol Strategy {
    /** 백스페이스 처리된 state를 sender에 입력. 완료 후 sender가 추가 처리해야 하면 false, 필요하지 않으면 true 반환 */
    static func backspace(from state: State, to sender: IMKTextInput, with oldState: State) -> Bool

    /** state에 저장된 문자열을 sender에 입력하고 조합 지속 */
    static func insert(from state: State, to sender: IMKTextInput, with oldState: State)

    /** state에 저장된 문자열을 sender에 입력하고 조합 종료 */
    static func flush(from state: State, to sender: IMKTextInput)

    /** 현재 입력 방식에서 두 context가 같다고 판단하는지 확인 */
    static func equal(left: EventContext, right: EventContext) -> Bool
}
