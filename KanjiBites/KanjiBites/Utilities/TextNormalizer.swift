import Foundation

enum TextNormalizer {
    static func normalize(_ text: String) -> String {
        let stripped = text.replacingOccurrences(
            of: "\\s",
            with: "",
            options: .regularExpression
        )
        let nfc = stripped.precomposedStringWithCanonicalMapping
        return nfc.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? nfc
    }
}
