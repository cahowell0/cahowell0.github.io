import Testing
import Foundation
@testable import KanjiBites

struct TextNormalizerTests {
    @Test func stripsWhitespace() {
        #expect(TextNormalizer.normalize("書 く") == "書く")
        #expect(TextNormalizer.normalize(" 書く ") == "書く")
        #expect(TextNormalizer.normalize("自然\n言語処理") == "自然言語処理")
    }

    @Test func nfcNormalization() {
        // か + combining dakuten (NFD) should equal が (NFC)
        let decomposed = "\u{304B}\u{3099}"
        let precomposed = "\u{304C}"
        #expect(TextNormalizer.normalize(decomposed) == TextNormalizer.normalize(precomposed))
    }

    @Test func emptyStringStaysEmpty() {
        #expect(TextNormalizer.normalize("") == "")
    }
}

struct SRSEngineTests {
    @Test func correctIncreasesInterval() {
        let result = SRSEngine.update(intervalDays: 1, easeFactor: 2.5, outcome: .correct)
        // max(1, Int(1 * 2.5)) = 2
        #expect(result.newIntervalDays == 2)
        // ease already at 2.5 cap, stays 2.5
        #expect(result.newEaseFactor == 2.5)
    }

    @Test func correctEaseGrowsBelowCap() {
        let result = SRSEngine.update(intervalDays: 4, easeFactor: 2.0, outcome: .correct)
        #expect(result.newIntervalDays == 8) // Int(4 * 2.0) = 8
        #expect(abs(result.newEaseFactor - 2.1) < 0.001)
    }

    @Test func kanaHintDoesNotChangeEase() {
        let result = SRSEngine.update(intervalDays: 4, easeFactor: 2.0, outcome: .correctKanaHint)
        // adjusted = max(1.3, 2.0 - 0.2) = 1.8, next = Int(4 * 1.8) = 7
        #expect(result.newIntervalDays == 7)
        #expect(result.newEaseFactor == 2.0)
    }

    @Test func kanaHintLowEaseUsesFloor() {
        // With low ease, max(1.3, ease - 0.2) = 1.3 is the floor
        let result = SRSEngine.update(intervalDays: 4, easeFactor: 1.4, outcome: .correctKanaHint)
        #expect(result.newIntervalDays == 5) // Int(4 * 1.3) = 5
    }

    @Test func heavyPenaltyReducesEase() {
        let result = SRSEngine.update(intervalDays: 5, easeFactor: 2.0, outcome: .correctHeavyPenalty)
        #expect(result.newIntervalDays == 6) // Int(5 * 1.2) = 6
        #expect(abs(result.newEaseFactor - 1.85) < 0.001)
    }

    @Test func incorrectResetsInterval() {
        let result = SRSEngine.update(intervalDays: 10, easeFactor: 2.5, outcome: .incorrect)
        #expect(result.newIntervalDays == 1)
        #expect(abs(result.newEaseFactor - 2.3) < 0.001)
    }

    @Test func easeFloorHoldsAtMinimum() {
        let result = SRSEngine.update(intervalDays: 1, easeFactor: 1.3, outcome: .incorrect)
        #expect(result.newEaseFactor == 1.3)
    }

    @Test func dueDateIsInFuture() {
        let ref = Date()
        let result = SRSEngine.update(intervalDays: 3, easeFactor: 2.0, outcome: .correct, referenceDate: ref)
        #expect(result.newDueDate > ref)
    }

    @Test func incorrectDueTomorrow() {
        let ref = Date()
        let result = SRSEngine.update(intervalDays: 7, easeFactor: 2.5, outcome: .incorrect, referenceDate: ref)
        let diff = Calendar.current.dateComponents([.day], from: ref, to: result.newDueDate).day ?? 0
        #expect(diff == 1)
    }
}
