// swiftlint:disable large_tuple

import InputMethodKit
import Carbon.HIToolbox.Events

/**
 입력 가능한 modifier -> USB HID Usage 매핑
 @see NSEvent.ModifierFlags
 */
enum ModifierUsage: UInt32 {
    case leftControl = 0xE0
    case leftShift
    case leftAlt
    case leftCommand
    case rightControl
    case rightShift
    case rightAlt
    case rightCommand
    case capsLock = 0x39
}

/** 특수한 키 -> USB HID Usage 매핑 */
enum SpecialUsage: UInt32 {
    case space = 0x2C
}

/**
 Virtual keycodes -> USB HID Usage 매핑
 @see <HIToolbox/Events.h>
 */
private let keyCodeToUsage: [Int: UInt32] = [
    kVK_ANSI_A: 0x04, kVK_ANSI_S: 0x16, kVK_ANSI_D: 0x07, kVK_ANSI_F: 0x09,
    kVK_ANSI_H: 0x0B, kVK_ANSI_G: 0x0A, kVK_ANSI_Z: 0x1D, kVK_ANSI_X: 0x1B,
    kVK_ANSI_C: 0x06, kVK_ANSI_V: 0x19, kVK_ANSI_B: 0x05, kVK_ANSI_Q: 0x14,
    kVK_ANSI_W: 0x1A, kVK_ANSI_E: 0x08, kVK_ANSI_R: 0x15, kVK_ANSI_Y: 0x1C,
    kVK_ANSI_T: 0x17, kVK_ANSI_1: 0x1E, kVK_ANSI_2: 0x1F, kVK_ANSI_3: 0x20,
    kVK_ANSI_4: 0x21, kVK_ANSI_6: 0x23, kVK_ANSI_5: 0x22, kVK_ANSI_Equal: 0x2E,
    kVK_ANSI_9: 0x26, kVK_ANSI_7: 0x24, kVK_ANSI_Minus: 0x2D, kVK_ANSI_8: 0x25,
    kVK_ANSI_0: 0x27, kVK_ANSI_RightBracket: 0x30, kVK_ANSI_O: 0x12, kVK_ANSI_U: 0x18,
    kVK_ANSI_LeftBracket: 0x2F, kVK_ANSI_I: 0x0C, kVK_ANSI_P: 0x13, kVK_ANSI_L: 0x0F,
    kVK_ANSI_J: 0x0D, kVK_ANSI_Quote: 0x34, kVK_ANSI_K: 0x0E, kVK_ANSI_Semicolon: 0x33,
    kVK_ANSI_Backslash: 0x31, kVK_ANSI_Comma: 0x36, kVK_ANSI_Slash: 0x38, kVK_ANSI_N: 0x11,
    kVK_ANSI_M: 0x10, kVK_ANSI_Period: 0x37, kVK_ANSI_Grave: 0x35, kVK_ANSI_KeypadDecimal: 0x63,
    kVK_ANSI_KeypadMultiply: 0x55, kVK_ANSI_KeypadPlus: 0x57, kVK_ANSI_KeypadClear: 0x53, kVK_ANSI_KeypadDivide: 0x54,
    kVK_ANSI_KeypadEnter: 0x58, kVK_ANSI_KeypadMinus: 0x56, kVK_ANSI_KeypadEquals: 0x67, kVK_ANSI_Keypad0: 0x62,
    kVK_ANSI_Keypad1: 0x59, kVK_ANSI_Keypad2: 0x5A, kVK_ANSI_Keypad3: 0x5B, kVK_ANSI_Keypad4: 0x5C,
    kVK_ANSI_Keypad5: 0x5D, kVK_ANSI_Keypad6: 0x5E, kVK_ANSI_Keypad7: 0x5F, kVK_ANSI_Keypad8: 0x60,
    kVK_ANSI_Keypad9: 0x61, kVK_Return: 0x28, kVK_Tab: 0x2B, kVK_Space: 0x2C,
    kVK_Delete: 0x2A, kVK_Escape: 0x29, kVK_Command: 0xE3, kVK_Shift: 0xE1,
    kVK_CapsLock: 0x39, kVK_Option: 0xE2, kVK_Control: 0xE0, kVK_RightCommand: 0xE7,
    kVK_RightShift: 0xE5, kVK_RightOption: 0xE6, kVK_RightControl: 0xE4, kVK_F17: 0x6C,
    kVK_VolumeUp: 0x80, kVK_VolumeDown: 0x81, kVK_Mute: 0x7F, kVK_F18: 0x6D,
    kVK_F19: 0x6E, kVK_F20: 0x6F, kVK_F5: 0x3E, kVK_F6: 0x3F,
    kVK_F7: 0x40, kVK_F3: 0x3C, kVK_F8: 0x41, kVK_F9: 0x42,
    kVK_F11: 0x44, kVK_F13: 0x68, kVK_F16: 0x6B, kVK_F14: 0x69,
    kVK_F10: 0x43, kVK_F12: 0x45, kVK_F15: 0x6A, kVK_Help: 0x75,
    kVK_Home: 0x4A, kVK_PageUp: 0x4B, kVK_ForwardDelete: 0x4C, kVK_F4: 0x3D,
    kVK_End: 0x4D, kVK_F2: 0x3B, kVK_PageDown: 0x4E, kVK_F1: 0x3A,
    kVK_LeftArrow: 0x50, kVK_RightArrow: 0x4F, kVK_DownArrow: 0x51, kVK_UpArrow: 0x52
]

/** (글자, 글자가 이후 조합을 허용하는지 여부) */
typealias CharTuple = (char: Character, composable: Bool)
/** 특정 키를 alt, shift와 합쳐서 눌렀을 때 해당하는 CharTuple */
typealias CharTupleMap = (base: CharTuple, alt: CharTuple?, shift: CharTuple?, altShift: CharTuple?)

/** 키보드 엔진 / 오토마타 */
protocol Engine {
    /** 메뉴 막대에 표시되는 이름 */
    static var name: String { get }

    /**
     USB HID Usage -> CharTupleMap 매핑
     @see https://www.usb.org/sites/default/files/hut1_21_0.pdf
     */
    static var usageToTupleMap: [UInt32: CharTupleMap] { get }

    /** 특정 글자 두개를 조합하려고 했을 때 결과 문자열 */
    static func combineChars(_ char0: Character, _ char1: Character) -> String

    /** 특정 글자를 분해하여 뒤로 삭제했을 때 결과 글자 */
    static func deleteBackward(_ char: Character) -> Character?
}

extension Engine {
    /** USB HID Usage -> CharTuple 매핑 */
    static func usageToTuple(_ usage: UInt32, _ isAltDown: Bool, _ isShiftDown: Bool) -> CharTuple? {
        let map = usageToTupleMap[usage]

        switch (isAltDown, isShiftDown) {
        case (true, true):
            return map?.altShift
        case (true, false):
            return map?.alt
        case (false, true):
            return map?.shift
        case (false, false):
            return map?.base
        }
    }

    /** NSEvent -> CharTuple 매핑 */
    static func eventToTuple(_ event: NSEvent) -> CharTuple? {
        // 모든 .keyUp 무시
        if event.type == .keyUp {
            return nil
        }

        let keyCode = event.keyCode
        let flags = event.modifierFlags

        // Control, Command: keyDown 상태인 경우 키 무시
        let isControlDown = flags.contains(.control)
        let isCommandDown = flags.contains(.command)
        if isControlDown || isCommandDown {
            return nil
        }

        // Alt, Shift: keyDown 상태
        let isAltDown = flags.contains(.option)
        let isShiftDown = flags.contains(.shift)

        if let usage = keyCodeToUsage[Int(keyCode)],
           let tuple = usageToTuple(usage, isAltDown, isShiftDown) {
            return tuple
        } else {
            return nil
        }
    }
}
