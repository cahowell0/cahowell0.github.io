import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var englishPrompt: String
    var kanaReading: String
    var kanjiAnswer: String
    var dueDate: Date
    var intervalDays: Int
    var easeFactor: Double

    @Relationship(deleteRule: .cascade, inverse: \ReviewEntry.card)
    var reviewHistory: [ReviewEntry]

    var deck: Deck?

    init(
        englishPrompt: String,
        kanaReading: String,
        kanjiAnswer: String,
        deck: Deck? = nil
    ) {
        self.id = UUID()
        self.englishPrompt = englishPrompt
        self.kanaReading = kanaReading
        self.kanjiAnswer = kanjiAnswer
        self.dueDate = Date()
        self.intervalDays = 1
        self.easeFactor = 2.5
        self.reviewHistory = []
        self.deck = deck
    }
}
