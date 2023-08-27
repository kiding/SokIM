// swiftlint:disable function_body_length

import Cocoa
import Foundation

let defaultRange = NSRange(location: NSNotFound, length: 0)

/** 입력 상태 및 변화 */
struct State: CustomStringConvertible {
    init() {}

    // MARK: - Input

    /** modifier 키 눌림 상태 (InputMonitor와 유사) */
    var modifier: [ModifierUsage: InputType] = [:]

    /** 현재 눌려있는 Input, 반복 입력 시 사용 */
    private(set) var down: Input?

    /** 새로운 Input 입력 처리 */
    mutating func next(_ input: Input) {
        let (usage, type) = (input.usage, input.type)

        // usage가 modifier인 경우
        if let key = ModifierUsage(rawValue: usage) {
            modifier[key] = type

            // Caps Lock / 오른쪽 Command: keyDown인 경우 한/A 전환
            if (
                (type, key) == (.keyDown, .capsLock)
                && Preferences.rotateShortcut == .capsLock
                && modifier[.leftShift] != .keyDown // Shift가 눌려있을 경우 rotate 차단
                && modifier[.rightShift] != .keyDown
            ) || (
                (type, key) == (.keyDown, .rightCommand)
                && Preferences.rotateShortcut == .rightCommand
            ) {
                commit()
                rotate()

                return
            }
        }
        // 그 외 경우 중 keyDown인 경우
        else if type == .keyDown {
            // 눌린 키를 down에 기록
            down = input

            // Command, Shift, Alt, Control
            let isCommandDown = modifier[.leftCommand] == .keyDown || modifier[.rightCommand] == .keyDown
            let isShiftDown = modifier[.leftShift] == .keyDown || modifier[.rightShift] == .keyDown
            let isAltDown = modifier[.leftAlt] == .keyDown || modifier[.rightAlt] == .keyDown
            let isControlDown = modifier[.leftControl] == .keyDown || modifier[.rightControl] == .keyDown

            // Command/Shift/Control + Space: keyDown인 경우 한/A 전환
            if (
                isCommandDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .commandSpace
            ) || (
                isShiftDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .shiftSpace
            ) || (
                isControlDown
                && usage == SpecialUsage.space.rawValue
                && Preferences.rotateShortcut == .controlSpace
            ) {
                commit()
                rotate()

                return
            }

            // Control, Command: keyDown 상태인 경우 키 무시
            if isControlDown || isCommandDown {
                debug("Input ignored: \(input) \(modifier)")

                return
            }

            // input 입력 시점부터 지금까지 걸린 시간
            let elapsed = ms(since: input.timestamp)

            // engine으로 현재 input을 tuple로 변환 가능하며 처리 시간이 3000ms 이내면
            if var tuple = engine.usageToTuple(usage, isAltDown, isShiftDown), elapsed < 3000 {
                // "₩ 대신 ` 입력" 처리
                if tuple.char == "₩" && Preferences.graveOverWon {
                    tuple.char = "`"
                }

                // 입력 진행
                next(tuple)
            }
            // 그 외 모든 경우
            else {
                debug("Input ignored: \(input) \(elapsed)ms")
            }
        }
        // 그 외 경우 중 keyUp인 경우
        else if type == .keyUp {
            // 같은 키면 down 삭제
            if down?.usage == input.usage {
                down = nil
            }
        }
        // 그 외 경우
        else {
            debug("Input ignored: \(input)")
        }
    }

    // MARK: - KeyboardEngine

    var engine: Engine.Type = TwoSetEngine.self
    init(engine: Engine.Type) {
        self.engine = engine
    }

    private let engines: [Engine.Type] = [QwertyEngine.self, TwoSetEngine.self]

    /** 사용 가능한 다음 engine으로 변경 */
    mutating func rotate() {
        debug()

        let count = engines.count
        let index = engines.firstIndex(where: { $0 == engine }) ?? 0
        engine = engines[(index + 1) % count]

        // swiftlint:disable:next force_cast
        (NSApp.delegate as! AppDelegate).statusBar.setEngine(engine)
    }

    // MARK: - CharTuple

    /** 완성 */
    private(set) var composed: String = ""  // å / å  / åé  |   /
    /** 조합 */
    private(set) var composing: String = "" //   / ´  /     | ㄱ / 가

    // TODO: 세벌식 모아치기 (두 글자 이상 조합) 지원
    /** 새로운 CharTuple 입력 처리 */
    mutating func next(_ tuple: CharTuple) {
        let (inputChar, inputMarked) = tuple
        let markedChar = composing.last
        var nextText: String

        // 조합 중인 마지막 글자가 있으면 새로 입력된 글자와 합치기
        if markedChar != nil {
            nextText = engine.combineChars(markedChar!, inputChar)
        }
        // 없으면 새로 입력된 글자 그대로 사용
        else {
            nextText = "\(inputChar)"
        }

        // 새로 입력된 글자가 이후 조합을 허용하면 조합으로 저장
        if inputMarked {
            composing = "\(nextText.popLast() ?? "?")"
        }
        // 아니면 조합 비움
        else {
            composing = ""
        }

        // 완성 갱신
        composed += nextText
    }

    /** 조합->완성 반영 */
    mutating func commit() {
        debug()

        composed += composing
        composing = ""
    }

    /** 완성/조합 초기화 */
    mutating func clear(composed includeComposed: Bool = true, composing includeComposing: Bool = false) {
        debug("composed: \(includeComposed), composing: \(includeComposing)")

        if includeComposed {
            composed = ""
        }

        if includeComposing {
            composing = ""
        }
    }

    mutating func deleteBackwardComposing() {
        // 조합에서 마지막 글자를 꺼냈을 때, 글자가 있다면
        if let oldLast = composing.popLast() {
            debug("oldLast: \(oldLast)")

            // engine을 통해 뒤로 삭제, 이후에도 글자가 남아있으면
            if let newLast = engine.deleteBackward(oldLast) {
                debug("newLast: \(newLast)")

                // 다시 조합에 붙임
                composing += "\(newLast)"
            }
        }
    }

    // MARK: - CustomStringConvertible

    var description: String { "\(engine) '\(composed)' [\(composing)] \(modifier)" }
}
