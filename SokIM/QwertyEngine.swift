/** 조합 전 -> 후 매핑 */
private let charsIntoChar: [[Character]: Character] = [
    ["`", "e"]: "è", ["`", "u"]: "ù", ["`", "i"]: "ì", ["`", "o"]: "ò", ["`", "a"]: "à", // ` + euioa
    ["´", "e"]: "é", ["´", "u"]: "ú", ["´", "i"]: "í", ["´", "o"]: "ó", ["´", "a"]: "á", ["´", "j"]: "j́", // ´ + euioaj
    ["¨", "e"]: "ë", ["¨", "y"]: "ÿ", ["¨", "u"]: "ü", ["¨", "i"]: "ï", ["¨", "o"]: "ö", ["¨", "a"]: "ä", // ¨ + eyuioa
    ["ˆ", "e"]: "ê", ["ˆ", "u"]: "û", ["ˆ", "i"]: "î", ["ˆ", "o"]: "ô", ["ˆ", "a"]: "â", // ˆ + euioa
    ["˜", "o"]: "õ", ["˜", "a"]: "ã", ["˜", "n"]: "ñ", // ˜ + oan

    ["`", "E"]: "È", ["`", "U"]: "Ù", ["`", "I"]: "Ì", ["`", "O"]: "Ò", ["`", "A"]: "À", // EUIOA
    ["´", "E"]: "É", ["´", "U"]: "Ú", ["´", "I"]: "Í", ["´", "O"]: "Ó", ["´", "A"]: "Á", ["´", "J"]: "J́", // EUIOAJ
    ["¨", "E"]: "Ë", ["¨", "Y"]: "Ÿ", ["¨", "U"]: "Ü", ["¨", "I"]: "Ï", ["¨", "O"]: "Ö", ["¨", "A"]: "Ä", // EYUIOA
    ["ˆ", "E"]: "Ê", ["ˆ", "U"]: "Û", ["ˆ", "I"]: "Î", ["ˆ", "O"]: "Ô", ["ˆ", "A"]: "Â", // EUIOA
    ["˜", "O"]: "Õ", ["˜", "A"]: "Ã", ["˜", "N"]: "Ñ" // OAN
]

/** 조합 후 -> 전 매핑 */
private let charIntoChars = flip(charsIntoChar)

struct QwertyEngine: Engine {
    static var name: String { "A" }

    static let usageToTupleMap: [UInt32: CharTupleMap] = [
        0x04: (("a", false), ("å", false), ("A", false), ("Å", false)), // Keyboard a and A
        0x05: (("b", false), ("∫", false), ("B", false), ("ı", false)), // Keyboard b and B
        0x06: (("c", false), ("ç", false), ("C", false), ("Ç", false)), // Keyboard c and C
        0x07: (("d", false), ("∂", false), ("D", false), ("Î", false)), // Keyboard d and D
        0x08: (("e", false), ("´", true), ("E", false), ("´", false)), // Keyboard e and E
        0x09: (("f", false), ("ƒ", false), ("F", false), ("Ï", false)), // Keyboard f and F
        0x0A: (("g", false), ("©", false), ("G", false), ("˝", false)), // Keyboard g and G
        0x0B: (("h", false), ("˙", false), ("H", false), ("Ó", false)), // Keyboard h and H
        0x0C: (("i", false), ("ˆ", true), ("I", false), ("ˆ", false)), // Keyboard i and I
        0x0D: (("j", false), ("∆", false), ("J", false), ("Ô", false)), // Keyboard j and J
        0x0E: (("k", false), ("˚", false), ("K", false), ("", false)), // Keyboard k and K
        0x0F: (("l", false), ("¬", false), ("L", false), ("Ò", false)), // Keyboard l and L
        0x10: (("m", false), ("µ", false), ("M", false), ("Â", false)), // Keyboard m and M
        0x11: (("n", false), ("˜", true), ("N", false), ("˜", false)), // Keyboard n and N
        0x12: (("o", false), ("ø", false), ("O", false), ("Ø", false)), // Keyboard o and O
        0x13: (("p", false), ("π", false), ("P", false), ("∏", false)), // Keyboard p and P
        0x14: (("q", false), ("œ", false), ("Q", false), ("Œ", false)), // Keyboard q and Q
        0x15: (("r", false), ("®", false), ("R", false), ("‰", false)), // Keyboard r and R
        0x16: (("s", false), ("ß", false), ("S", false), ("Í", false)), // Keyboard s and S
        0x17: (("t", false), ("†", false), ("T", false), ("ˇ", false)), // Keyboard t and T
        0x18: (("u", false), ("¨", true), ("U", false), ("¨", false)), // Keyboard u and U
        0x19: (("v", false), ("√", false), ("V", false), ("◊", false)), // Keyboard v and V
        0x1A: (("w", false), ("∑", false), ("W", false), ("„", false)), // Keyboard w and W
        0x1B: (("x", false), ("≈", false), ("X", false), ("˛", false)), // Keyboard x and X
        0x1C: (("y", false), ("¥", false), ("Y", false), ("Á", false)), // Keyboard y and Y
        0x1D: (("z", false), ("Ω", false), ("Z", false), ("¸", false)), // Keyboard z and Z

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
        0x35: (("`", false), ("`", true), ("~", false), ("`", false)), // Keyboard Grave Accent and Tilde
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

    static func combineChars(_ char0: Character, _ char1: Character) -> String {
        debug()

        if let combinedChar = charsIntoChar[[char0, char1]] {
            return "\(combinedChar)"
        } else {
            return "\(char0)\(char1)"
        }
    }

    static func deleteBackward(_ char: Character) -> Character? {
        debug()

        if let chars = charIntoChars[char] {
            return chars.first
        } else {
            return nil
        }
    }
}
