import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var createdDate: Date

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.cards = []
    }

    var dueCardCount: Int {
        let now = Date()
        return cards.filter { $0.dueDate <= now }.count
    }
}
