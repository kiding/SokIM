import InputMethodKit

/** 입력 방식 */
protocol Strategy {
    /** 백스페이스를 state로 처리 후 sender에 입력. 완료 후 sender가 추가 처리해야 하면 false, 필요하지 않으면 true 반환 */
    static func backspace(with state: inout State, to sender: IMKTextInput) -> Bool

    /** CharTuple를 state로 처리 후 sender에 입력 */
    static func tuples(_ tuples: [CharTuple], with state: inout State, to sender: IMKTextInput)

    /** state에 저장된 문자열을 sender에 입력하고 상태 초기화 */
    static func flush(with state: inout State, to sender: IMKTextInput)

    /** 현재 입력 방식에서 두 context가 같다고 판단하는지 확인 */
    static func equal(left: EventContext, right: EventContext) -> Bool
}
