import Foundation
import SwiftData

enum ReviewOutcome {
    static let correct = "correct"
    static let correctKanaHint = "correct_kana_hint"
    static let correctHeavyPenalty = "correct_heavy_penalty"
    static let incorrect = "incorrect"
}

enum HintsRevealed {
    static let none = "none"
    static let kana = "kana"
    static let kanji = "kanji"
}

@Model
final class ReviewEntry {
    var id: UUID
    var date: Date
    var outcome: String
    var attemptsUsed: Int
    var hintsRevealed: String

    var card: Card?

    init(outcome: String, attemptsUsed: Int, hintsRevealed: String, card: Card? = nil) {
        self.id = UUID()
        self.date = Date()
        self.outcome = outcome
        self.attemptsUsed = attemptsUsed
        self.hintsRevealed = hintsRevealed
        self.card = card
    }
}
