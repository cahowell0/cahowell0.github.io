import Foundation

enum StudyOutcome {
    case correct
    case correctKanaHint
    case correctHeavyPenalty
    case incorrect
}

struct SRSEngine {
    struct UpdateResult {
        let newIntervalDays: Int
        let newEaseFactor: Double
        let newDueDate: Date
    }

    static func update(
        intervalDays: Int,
        easeFactor: Double,
        outcome: StudyOutcome,
        referenceDate: Date = Date()
    ) -> UpdateResult {
        let calendar = Calendar.current

        switch outcome {
        case .correct:
            let next = max(1, Int(Double(intervalDays) * easeFactor))
            let newEase = min(2.5, easeFactor + 0.1)
            let due = calendar.date(byAdding: .day, value: next, to: referenceDate)!
            return UpdateResult(newIntervalDays: next, newEaseFactor: newEase, newDueDate: due)

        case .correctKanaHint:
            let adjusted = max(1.3, easeFactor - 0.2)
            let next = max(1, Int(Double(intervalDays) * adjusted))
            let due = calendar.date(byAdding: .day, value: next, to: referenceDate)!
            return UpdateResult(newIntervalDays: next, newEaseFactor: easeFactor, newDueDate: due)

        case .correctHeavyPenalty:
            let next = max(1, Int(Double(intervalDays) * 1.2))
            let newEase = max(1.3, easeFactor - 0.15)
            let due = calendar.date(byAdding: .day, value: next, to: referenceDate)!
            return UpdateResult(newIntervalDays: next, newEaseFactor: newEase, newDueDate: due)

        case .incorrect:
            let newEase = max(1.3, easeFactor - 0.2)
            let due = calendar.date(byAdding: .day, value: 1, to: referenceDate)!
            return UpdateResult(newIntervalDays: 1, newEaseFactor: newEase, newDueDate: due)
        }
    }
}
