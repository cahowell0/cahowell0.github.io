import SwiftUI
import SwiftData

// MARK: - Supporting Types

enum StudyPhase: Equatable {
    case attempt(number: Int)
    case result(outcome: StudyOutcome)

    static func == (lhs: StudyPhase, rhs: StudyPhase) -> Bool {
        switch (lhs, rhs) {
        case (.attempt(let a), .attempt(let b)):
            return a == b
        case (.result(let a), .result(let b)):
            switch (a, b) {
            case (.correct, .correct),
                 (.correctKanaHint, .correctKanaHint),
                 (.correctHeavyPenalty, .correctHeavyPenalty),
                 (.incorrect, .incorrect):
                return true
            default: return false
            }
        default: return false
        }
    }
}

struct HintState {
    var kanaRevealed: Bool = false
    var kanjiRevealed: Bool = false
    var kanaRevealedBeforeAnswer: Bool = false
}

struct SessionSummary {
    var correct: Int = 0
    var correctKanaHint: Int = 0
    var correctHeavyPenalty: Int = 0
    var incorrect: Int = 0
    var total: Int { correct + correctKanaHint + correctHeavyPenalty + incorrect }
}

// MARK: - ViewModel

@MainActor
@Observable
final class StudySessionViewModel {
    private var queue: [Card]
    private(set) var currentIndex: Int = 0
    private(set) var phase: StudyPhase = .attempt(number: 1)
    private(set) var hintState: HintState = HintState()
    private(set) var summary: SessionSummary = SessionSummary()
    private(set) var sessionEnded: Bool = false

    var userDrawingImage: UIImage? = nil
    var recognizedText: String = ""

    private let modelContext: ModelContext

    var currentCard: Card? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var isLastCard: Bool { currentIndex >= queue.count - 1 }

    var queueCount: Int { queue.count }

    init(cards: [Card], modelContext: ModelContext) {
        let now = Date()
        self.queue = cards.filter { $0.dueDate <= now }.shuffled()
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func showKana() {
        guard case .attempt = phase else { return }
        hintState.kanaRevealed = true
        hintState.kanaRevealedBeforeAnswer = true
    }

    func showKanji() {
        guard let card = currentCard, case .attempt = phase else { return }
        hintState.kanjiRevealed = true
        commitResult(card: card, outcome: .incorrect, attemptsUsed: currentAttemptNumber)
        phase = .result(outcome: .incorrect)
    }

    private var currentAttemptNumber: Int {
        if case .attempt(let n) = phase { return n }
        return 1
    }

    func submitAnswer(recognized: String, expectedNormalized: String) {
        guard let card = currentCard, case .attempt(let n) = phase else { return }

        let normalizedRecognized = TextNormalizer.normalize(recognized)

        if normalizedRecognized == expectedNormalized {
            let outcome: StudyOutcome
            if n == 3 || hintState.kanaRevealedBeforeAnswer {
                outcome = (n == 3) ? .correctHeavyPenalty : .correctKanaHint
            } else {
                outcome = .correct
            }
            commitResult(card: card, outcome: outcome, attemptsUsed: n)
            phase = .result(outcome: outcome)
        } else {
            handleFailure(attemptNumber: n)
        }
    }

    private func handleFailure(attemptNumber: Int) {
        switch attemptNumber {
        case 1:
            phase = .attempt(number: 2)
        case 2:
            hintState.kanaRevealed = true
            phase = .attempt(number: 3)
        default:
            guard let card = currentCard else { return }
            hintState.kanjiRevealed = true
            commitResult(card: card, outcome: .incorrect, attemptsUsed: 3)
            phase = .result(outcome: .incorrect)
        }
    }

    func advanceToNextCard() {
        if currentIndex >= queue.count - 1 {
            sessionEnded = true
            return
        }
        currentIndex += 1
        phase = .attempt(number: 1)
        hintState = HintState()
        userDrawingImage = nil
        recognizedText = ""
    }

    func endSession() {
        sessionEnded = true
    }

    // MARK: - Persistence

    private func commitResult(card: Card, outcome: StudyOutcome, attemptsUsed: Int) {
        let result = SRSEngine.update(
            intervalDays: card.intervalDays,
            easeFactor: card.easeFactor,
            outcome: outcome
        )
        card.intervalDays = result.newIntervalDays
        card.easeFactor = result.newEaseFactor
        card.dueDate = result.newDueDate

        let hintsRevealedStr: String
        if hintState.kanjiRevealed {
            hintsRevealedStr = HintsRevealed.kanji
        } else if hintState.kanaRevealed {
            hintsRevealedStr = HintsRevealed.kana
        } else {
            hintsRevealedStr = HintsRevealed.none
        }

        let outcomeStr: String
        switch outcome {
        case .correct: outcomeStr = ReviewOutcome.correct
        case .correctKanaHint: outcomeStr = ReviewOutcome.correctKanaHint
        case .correctHeavyPenalty: outcomeStr = ReviewOutcome.correctHeavyPenalty
        case .incorrect: outcomeStr = ReviewOutcome.incorrect
        }

        let entry = ReviewEntry(
            outcome: outcomeStr,
            attemptsUsed: attemptsUsed,
            hintsRevealed: hintsRevealedStr,
            card: card
        )
        card.reviewHistory.append(entry)
        modelContext.insert(entry)

        switch outcome {
        case .correct: summary.correct += 1
        case .correctKanaHint: summary.correctKanaHint += 1
        case .correctHeavyPenalty: summary.correctHeavyPenalty += 1
        case .incorrect: summary.incorrect += 1
        }

        try? modelContext.save()
    }
}
