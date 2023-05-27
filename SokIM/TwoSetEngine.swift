/** 입력 가능한 초성 배열 */
private let choArr: [Character] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
/** 초성 -> 순서 숫자 매핑 */
private let choMap = flip(choArr)
/** 입력 가능한 중성 배열 */
private let jungArr: [Character] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
/** 중성 -> 순서 숫자 매핑 */
private let jungMap = flip(jungArr)
/** 입력 가능한 종성 배열 */
private let jongArr: [Character] = Array(" ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
/** 종성 -> 순서 숫자 매핑 */
private let jongMap = flip(jongArr)

/** 조합 전 -> 후 매핑 */
private let jamosIntoJamo: [[Character]: Character] = [
    ["ㅗ", "ㅏ"]: "ㅘ", ["ㅗ", "ㅐ"]: "ㅙ", ["ㅗ", "ㅣ"]: "ㅚ", ["ㅜ", "ㅓ"]: "ㅝ", ["ㅜ", "ㅔ"]: "ㅞ", ["ㅜ", "ㅣ"]: "ㅟ",
    ["ㅡ", "ㅣ"]: "ㅢ", ["ㄱ", "ㅅ"]: "ㄳ", ["ㄴ", "ㅈ"]: "ㄵ", ["ㄴ", "ㅎ"]: "ㄶ", ["ㄹ", "ㄱ"]: "ㄺ", ["ㄹ", "ㅁ"]: "ㄻ",
    ["ㄹ", "ㅂ"]: "ㄼ", ["ㄹ", "ㅅ"]: "ㄽ", ["ㄹ", "ㅌ"]: "ㄾ", ["ㄹ", "ㅍ"]: "ㄿ", ["ㄹ", "ㅎ"]: "ㅀ", ["ㅂ", "ㅅ"]: "ㅄ"
]
/** 조합 후 -> 전 매핑 */
private let jamoIntoJamos = flip(jamosIntoJamo)

private struct Hangul {
    /** 초성, 단독 자음 포함 */
    var cho: Character?
    /** 중성, 단독 모음 포함 */
    var jung: Character?
    /** 종성 */
    var jong: Character?

    init?(_ character: Character) {
        switch character {
            // 초성만, 단독 자음
        case "ㄱ"..."ㅎ" where choMap[character] != nil:
            cho = character

            // 중성만, 단독 모음
        case "ㅏ"..."ㅣ" where jungMap[character] != nil:
            jung = character

            // 초성+중성 또는 초성+중성+종성
        case "가"..."힣":
            let offsetIdx = Int(character.unicodeScalars.first!.value - 0xAC00)
            let jongIdx = offsetIdx % 28
            let jungIdx = ((offsetIdx - jongIdx) / 28) % 21
            let choIdx = (offsetIdx - jongIdx - jungIdx * 28) / (28 * 21)

            cho = choArr[choIdx]
            jung = jungArr[jungIdx]
            jong = jongIdx == 0 ? nil : jongArr[jongIdx]

            // 완성형 한글이 아니거나 잘못된 조합이면 nil
        default:
            return nil
        }
    }

    init?(_ cho: Character?, _ jung: Character?, _ jong: Character?) {
        switch (cho, jung, jong) {
            // 초성만, 단독 자음
        case (let cho?, nil, nil) where choMap[cho] != nil:
            self.cho = cho

            // 중성만, 단독 모음
        case (nil, let jung?, nil) where jungMap[jung] != nil:
            self.jung = jung

            // 초성+중성
        case (let cho?, let jung?, nil) where choMap[cho] != nil && jungMap[jung] != nil:
            self.cho = cho
            self.jung = jung

            // 초성+중성+종성
        case (let cho?, let jung?, let jong?) where choMap[cho] != nil && jungMap[jung] != nil && jongMap[jong] != nil:
            self.cho = cho
            self.jung = jung
            self.jong = jong

        default:
            return nil
        }
    }

    var character: Character? {
        switch (cho, jung, jong) {
            // 초성만, 단독 자음
        case (let cho?, nil, nil):
            return cho

            // 중성만, 단독 모음
        case (nil, let jung?, nil):
            return jung

            // 초성+중성 또는 초성+중성+종성
        case (let cho?, let jung?, _):
            var offsetIdx = 0

            if let choIdx = choMap[cho] {
                offsetIdx += choIdx * 28 * 21
            }
            if let jungIdx = jungMap[jung] {
                offsetIdx += jungIdx * 28
            }
            if let jong = jong, let jongIdx = jongMap[jong] {
                offsetIdx += jongIdx
            }

            return Character(Unicode.Scalar(0xAC00 + offsetIdx)!)

        default:
            return nil
        }
    }
}

struct TwoSetEngine: Engine {
    static var name: String { "가" }

    static let usageToTupleMap: [UInt32: CharTupleMap] = [
        0x04: (("ㅁ", true), ("a", false), ("ㅁ", true), ("A", false)), // Keyboard a and A
        0x05: (("ㅠ", true), ("b", false), ("ㅠ", true), ("B", false)), // Keyboard b and B
        0x06: (("ㅊ", true), ("c", false), ("ㅊ", true), ("C", false)), // Keyboard c and C
        0x07: (("ㅇ", true), ("d", false), ("ㅇ", true), ("D", false)), // Keyboard d and D
        0x08: (("ㄷ", true), ("e", false), ("ㄸ", true), ("E", false)), // Keyboard e and E
        0x09: (("ㄹ", true), ("f", false), ("ㄹ", true), ("F", false)), // Keyboard f and F
        0x0A: (("ㅎ", true), ("g", false), ("ㅎ", true), ("G", false)), // Keyboard g and G
        0x0B: (("ㅗ", true), ("h", false), ("ㅗ", true), ("H", false)), // Keyboard h and H
        0x0C: (("ㅑ", true), ("i", false), ("ㅑ", true), ("I", false)), // Keyboard i and I
        0x0D: (("ㅓ", true), ("j", false), ("ㅓ", true), ("J", false)), // Keyboard j and J
        0x0E: (("ㅏ", true), ("k", false), ("ㅏ", true), ("K", false)), // Keyboard k and K
        0x0F: (("ㅣ", true), ("l", false), ("ㅣ", true), ("L", false)), // Keyboard l and L
        0x10: (("ㅡ", true), ("m", false), ("ㅡ", true), ("M", false)), // Keyboard m and M
        0x11: (("ㅜ", true), ("n", false), ("ㅜ", true), ("N", false)), // Keyboard n and N
        0x12: (("ㅐ", true), ("o", false), ("ㅒ", true), ("O", false)), // Keyboard o and O
        0x13: (("ㅔ", true), ("p", false), ("ㅖ", true), ("P", false)), // Keyboard p and P
        0x14: (("ㅂ", true), ("q", false), ("ㅃ", true), ("Q", false)), // Keyboard q and Q
        0x15: (("ㄱ", true), ("r", false), ("ㄲ", true), ("R", false)), // Keyboard r and R
        0x16: (("ㄴ", true), ("s", false), ("ㄴ", true), ("S", false)), // Keyboard s and S
        0x17: (("ㅅ", true), ("t", false), ("ㅆ", true), ("T", false)), // Keyboard t and T
        0x18: (("ㅕ", true), ("u", false), ("ㅕ", true), ("U", false)), // Keyboard u and U
        0x19: (("ㅍ", true), ("v", false), ("ㅍ", true), ("V", false)), // Keyboard v and V
        0x1A: (("ㅈ", true), ("w", false), ("ㅉ", true), ("W", false)), // Keyboard w and W
        0x1B: (("ㅌ", true), ("x", false), ("ㅌ", true), ("X", false)), // Keyboard x and X
        0x1C: (("ㅛ", true), ("y", false), ("ㅛ", true), ("Y", false)), // Keyboard y and Y
        0x1D: (("ㅋ", true), ("z", false), ("ㅋ", true), ("Z", false)), // Keyboard z and Z

        0x1E: (("1", false), ("¡", false), ("!", false), ("⁄", false)), // Keyboard 1 and !
        0x1F: (("2", false), ("™", false), ("@", false), ("€", false)), // Keyboard 2 and @
        0x20: (("3", false), ("£", false), ("#", false), ("‹", false)), // Keyboard 3 and #
        0x21: (("4", false), ("¢", false), ("$", false), ("›", false)), // Keyboard 4 and $
        0x22: (("5", false), ("∞", false), ("%", false), ("ﬁ", false)), // Keyboard 5 and %
        0x23: (("6", false), ("§", false), ("^", false), ("ﬂ", false)), // Keyboard 6 and ∧
        0x24: (("7", false), ("¶", false), ("&", false), ("‡", false)), // Keyboard 7 and &
        0x25: (("8", false), ("•", false), ("*", false), ("°", false)), // Keyboard 8 and *
        0x26: (("9", false), ("ª", false), ("(", false), ("·", false)), // Keyboard 9 and (
        0x27: (("0", false), ("º", false), (")", false), ("‚", false)), // Keyboard 0 and )

        0x2C: ((" ", false), (" ", false), (" ", false), (" ", false)), // Keyboard Spacebar
        0x2D: (("-", false), ("–", false), ("_", false), ("—", false)), // Keyboard - and (underscore)
        0x2E: (("=", false), ("≠", false), ("+", false), ("±", false)), // Keyboard = and +
        0x2F: (("[", false), ("“", false), ("{", false), ("”", false)), // Keyboard [ and {
        0x30: (("]", false), ("‘", false), ("}", false), ("’", false)), // Keyboard ] and }
        0x31: (("\\", false), ("«", false), ("|", false), ("»", false)), // Keyboard \ and |
        0x32: (("\\", false), ("«", false), ("|", false), ("»", false)), // Keyboard Non-US # and ~
        0x33: ((";", false), ("…", false), (":", false), ("Ú", false)), // Keyboard ; and :
        0x34: (("'", false), ("æ", false), ("\"", false), ("Æ", false)), // Keyboard ‘ and “

        0x35: (("₩", false), ("`", false), ("~", false), ("~", false)), // Keyboard Grave Accent and Tilde

        0x36: ((",", false), ("≤", false), ("<", false), ("¯", false)), // Keyboard , and <
        0x37: ((".", false), ("≥", false), (">", false), ("˘", false)), // Keyboard . and >
        0x38: (("/", false), ("÷", false), ("?", false), ("¿", false)), // Keyboard / and ?
        0x54: (("/", false), ("/", false), ("/", false), ("/", false)), // Keypad /
        0x55: (("*", false), ("*", false), ("*", false), ("*", false)), // Keypad *
        0x56: (("-", false), ("-", false), ("-", false), ("-", false)), // Keypad -
        0x57: (("+", false), ("+", false), ("+", false), ("+", false)), // Keypad +

        0x59: (("1", false), ("1", false), ("1", false), ("1", false)), // Keypad 1 and End
        0x5A: (("2", false), ("2", false), ("2", false), ("2", false)), // Keypad 2 and Down Arrow
        0x5B: (("3", false), ("3", false), ("3", false), ("3", false)), // Keypad 3 and PageDn
        0x5C: (("4", false), ("4", false), ("4", false), ("4", false)), // Keypad 4 and Left Arrow
        0x5D: (("5", false), ("5", false), ("5", false), ("5", false)), // Keypad 5
        0x5E: (("6", false), ("6", false), ("6", false), ("6", false)), // Keypad 6 and Right Arrow
        0x5F: (("7", false), ("7", false), ("7", false), ("7", false)), // Keypad 7 and Home
        0x60: (("8", false), ("8", false), ("8", false), ("8", false)), // Keypad 8 and Up Arrow
        0x61: (("9", false), ("9", false), ("9", false), ("9", false)), // Keypad 9 and PageUp
        0x62: (("0", false), ("0", false), ("0", false), ("0", false)), // Keypad 0 and Insert
        0x63: ((".", false), (".", false), (".", false), (".", false)), // Keypad . and Delete
        0x64: (("\\", false), ("«", false), ("|", false), ("»", false)) // Keyboard Non-US \ and |
    ]

    /** 한글 조합 영역 */
    private static func combineHanguls(_ hangul0: Hangul?, _ hangul1: Hangul?) -> (Hangul?, Hangul?) {
        debug()

        switch ((hangul0?.cho, hangul0?.jung, hangul0?.jong), (hangul1?.cho, hangul1?.jung, hangul1?.jong)) {
            // ㄲ + ㅏ = 까
        case ((let cho0?, nil, nil), (nil, let jung1?, nil)):
            return (Hangul(cho0, jung1, nil), nil)

            // ㅡ + ㅣ = ㅢ / ㅣ + ㅣ = ㅣㅣ
        case ((nil, let jung0?, nil), (nil, let jung1?, nil)):
            return (Hangul(nil, jamosIntoJamo[[jung0, jung1]], nil), nil)

            // 그 + ㄱ = 극 / 그 + ㄸ = 그ㄸ
        case ((let cho0?, let jung0?, nil), (let cho1?, nil, nil)):
            return (Hangul(cho0, jung0, cho1), nil)

            // 그 + ㅣ = 긔 / 그 + ㅡ = 그ㅡ
        case ((let cho0?, let jung0?, nil), (nil, let jung1?, nil)):
            let jung = jamosIntoJamo[[jung0, jung1]]
            return (jung != nil ? Hangul(cho0, jung, nil) : nil, nil)

            // 갑 + ㅅ = 값 / 갑 + ㅃ = 갑ㅃ
        case ((let cho0?, let jung0?, let jong0?), (let cho1?, nil, nil)):
            let jong = jamosIntoJamo[[jong0, cho1]]
            return (jong != nil ? Hangul(cho0, jung0, jong): nil, nil)

            // 값 + ㅏ = 갑사 / 간 + ㅏ = 가나
        case ((let cho0?, let jung0?, let jong0?), (nil, let jung1?, nil)):
            if let jongs = jamoIntoJamos[jong0] {
                return (Hangul(cho0, jung0, jongs.first), Hangul(jongs.last, jung1, nil))
            } else {
                return (Hangul(cho0, jung0, nil), Hangul(jong0, jung1, nil))
            }

            // 그 외 모든 경우
        default:
            return (nil, nil)
        }
    }

    static func combineChars(_ char0: Character, _ char1: Character) -> String {
        debug()

        // 조합 시도
        let (combined0, combined1) = combineHanguls(Hangul(char0), Hangul(char1))

        switch (combined0?.character, combined1?.character) {
            // 조합 성공: 두글자
        case (let combinedChar0?, let combinedChar1?):
            return "\(combinedChar0)\(combinedChar1)"

            // 조합 성공: 한글자
        case (let combinedChar0?, nil):
            return "\(combinedChar0)"

            // 조합 실패: 원본 그대로 사용
        default:
            return "\(char0)\(char1)"
        }
    }

    static func deleteBackward(_ char: Character) -> Character? {
        debug()

        let hangul = Hangul(char)

        switch (hangul?.cho, hangul?.jung, hangul?.jong) {
            // ㄲ -> nil / ㄱ -> nil
        case (_?, nil, nil):
            return nil

            // ㅢ -> ㅡ / ㅡ -> nil
        case (nil, let jung?, nil):
            if let jungs = jamoIntoJamos[jung] {
                return Hangul(nil, jungs.first, nil)?.character
            } else {
                return Hangul(nil, nil, nil)?.character
            }

            // 긔 -> 그 / 그 -> ㄱ
        case (let cho?, let jung?, nil):
            if let jungs = jamoIntoJamos[jung] {
                return Hangul(cho, jungs.first, nil)?.character
            } else {
                return Hangul(cho, nil, nil)?.character
            }

            // 값 -> 갑 / 갑 -> 가
        case (let cho?, let jung?, let jong?):
            if let jongs = jamoIntoJamos[jong] {
                return Hangul(cho, jung, jongs.first)?.character
            } else {
                return Hangul(cho, jung, nil)?.character
            }
        default:
            return nil
        }
    }
}
