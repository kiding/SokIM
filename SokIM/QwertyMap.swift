import Foundation

class ABCMap: KeyboardMap {
    static let usageToChar: [UInt32: [MapTuple]] = [
        0x04: [
            (("a", false), ("å", false), ("A", false), ("Å", false)), // Keyboard a and A
            (("b", false), ("∫", false), ("B", false), ("ı", false)), // Keyboard b and B
            (("c", false), ("ç", false), ("C", false), ("Ç", false)), // Keyboard c and C
            (("d", false), ("∂", false), ("D", false), ("Î", false)), // Keyboard d and D
            (("e", false), ("´", true), ("E", false), ("´", false)), // Keyboard e and E
            (("f", false), ("ƒ", false), ("F", false), ("Ï", false)), // Keyboard f and F
            (("g", false), ("©", false), ("G", false), ("˝", false)), // Keyboard g and G
            (("h", false), ("˙", false), ("H", false), ("Ó", false)), // Keyboard h and H
            (("i", false), ("ˆ", true), ("I", false), ("ˆ", false)), // Keyboard i and I
            (("j", false), ("∆", false), ("J", false), ("Ô", false)), // Keyboard j and J
            (("k", false), ("˚", false), ("K", false), ("", false)), // Keyboard k and K
            (("l", false), ("¬", false), ("L", false), ("Ò", false)), // Keyboard l and L
            (("m", false), ("µ", false), ("M", false), ("Â", false)), // Keyboard m and M
            (("n", false), ("˜", true), ("N", false), ("˜", false)), // Keyboard n and N
            (("o", false), ("ø", false), ("O", false), ("Ø", false)), // Keyboard o and O
            (("p", false), ("π", false), ("P", false), ("∏", false)), // Keyboard p and P
            (("q", false), ("œ", false), ("Q", false), ("Œ", false)), // Keyboard q and Q
            (("r", false), ("®", false), ("R", false), ("‰", false)), // Keyboard r and R
            (("s", false), ("ß", false), ("S", false), ("Í", false)), // Keyboard s and S
            (("t", false), ("†", false), ("T", false), ("ˇ", false)), // Keyboard t and T
            (("u", false), ("¨", true), ("U", false), ("¨", false)), // Keyboard u and U
            (("v", false), ("√", false), ("V", false), ("◊", false)), // Keyboard v and V
            (("w", false), ("∑", false), ("W", false), ("„", false)), // Keyboard w and W
            (("x", false), ("≈", false), ("X", false), ("˛", false)), // Keyboard x and X
            (("y", false), ("¥", false), ("Y", false), ("Á", false)), // Keyboard y and Y
            (("z", false), ("Ω", false), ("Z", false), ("¸", false)), // Keyboard z and Z
            (("1", false), ("¡", false), ("!", false), ("⁄", false)), // Keyboard 1 and !
            (("2", false), ("™", false), ("@", false), ("€", false)), // Keyboard 2 and @
            (("3", false), ("£", false), ("#", false), ("‹", false)), // Keyboard 3 and #
            (("4", false), ("¢", false), ("$", false), ("›", false)), // Keyboard 4 and $
            (("5", false), ("∞", false), ("%", false), ("ﬁ", false)), // Keyboard 5 and %
            (("6", false), ("§", false), ("^", false), ("ﬂ", false)), // Keyboard 6 and ∧
            (("7", false), ("¶", false), ("&", false), ("‡", false)), // Keyboard 7 and &
            (("8", false), ("•", false), ("*", false), ("°", false)), // Keyboard 8 and *
            (("9", false), ("ª", false), ("(", false), ("·", false)), // Keyboard 9 and (
            (("0", false), ("º", false), (")", false), ("‚", false)), // Keyboard 0 and )
            (("\n", false), ("\n", false), ("\n", false), ("\n", false)) // Keyboard Return (ENTER)
        ],
        0x2B: [
            (("\t", false), ("\t", false), ("\t", false), ("\t", false)), // Keyboard Tab
            ((" ", false), (" ", false), (" ", false), (" ", false)), // Keyboard Spacebar
            (("-", false), ("–", false), ("_", false), ("—", false)), // Keyboard - and (underscore)
            (("=", false), ("≠", false), ("+", false), ("±", false)), // Keyboard = and +
            (("[", false), ("“", false), ("{", false), ("”", false)), // Keyboard [ and {
            (("]", false), ("‘", false), ("}", false), ("’", false)), // Keyboard ] and }
            (("\\", false), ("«", false), ("|", false), ("»", false)), // Keyboard \ and |
            (("#", false), ("«", false), ("~", false), ("»", false)), // Keyboard Non-US # and ~
            ((";", false), ("…", false), (":", false), ("Ú", false)), // Keyboard ; and :
            (("'", false), ("æ", false), ("\"", false), ("Æ", false)), // Keyboard ‘ and “
            (("`", false), ("`", true), ("~", false), ("`", false)), // Keyboard Grave Accent and Tilde
            ((",", false), ("≤", false), ("<", false), ("¯", false)), // Keyboard , and <
            ((".", false), ("≥", false), (">", false), ("˘", false)), // Keyboard . and >
            (("/", false), ("÷", false), ("?", false), ("¿", false)) // Keyboard / and ?
        ],
        0x54: [
            (("/", false), ("/", false), ("/", false), ("/", false)), // Keypad /
            (("*", false), ("*", false), ("*", false), ("*", false)), // Keypad *
            (("-", false), ("-", false), ("-", false), ("-", false)), // Keypad -
            (("+", false), ("+", false), ("+", false), ("+", false)), // Keypad +
            (("\n", false), ("\n", false), ("\n", false), ("\n", false)), // Keypad ENTER
            (("1", false), ("1", false), ("1", false), ("1", false)), // Keypad 1 and End
            (("2", false), ("2", false), ("2", false), ("2", false)), // Keypad 2 and Down Arrow
            (("3", false), ("3", false), ("3", false), ("3", false)), // Keypad 3 and PageDn
            (("4", false), ("4", false), ("4", false), ("4", false)), // Keypad 4 and Left Arrow
            (("5", false), ("5", false), ("5", false), ("5", false)), // Keypad 5
            (("6", false), ("6", false), ("6", false), ("6", false)), // Keypad 6 and Right Arrow
            (("7", false), ("7", false), ("7", false), ("7", false)), // Keypad 7 and Home
            (("8", false), ("8", false), ("8", false), ("8", false)), // Keypad 8 and Up Arrow
            (("9", false), ("9", false), ("9", false), ("9", false)), // Keypad 9 and PageUp
            (("0", false), ("0", false), ("0", false), ("0", false)), // Keypad 0 and Insert
            ((".", false), (".", false), (".", false), (".", false)), // Keypad . and Delete
            (("\\", false), ("«", false), ("|", false), ("»", false)) // Keyboard Non-US \ and |
        ]
    ]

    static private let charsToChar: [Set<Character>: Character] = [
        ["`", "è"]: "è", ["`", "u"]: "ù", ["`", "i"]: "ì", ["`", "o"]: "ò", ["`", "a"]: "à", // euioa
        ["´", "e"]: "é", ["´", "u"]: "ú", ["´", "i"]: "í", ["´", "o"]: "ó", ["´", "a"]: "á", ["´", "j"]: "j́", // euioaj
        ["¨", "e"]: "ë", ["¨", "y"]: "ÿ", ["¨", "u"]: "ü", ["¨", "i"]: "ï", ["¨", "o"]: "ö", ["¨", "a"]: "ä", // eyuioa
        ["ˆ", "e"]: "ê", ["ˆ", "u"]: "û", ["ˆ", "i"]: "î", ["ˆ", "o"]: "ô", ["ˆ", "a"]: "â", // euioa
        ["˜", "o"]: "õ", ["˜", "a"]: "ã", ["˜", "n"]: "ñ" // oan
    ]

    static func combineChars(_ char1: Character, _ char2: Character) -> Character? {
        debug()

        return charsToChar[[char1, char2]]
    }
}
