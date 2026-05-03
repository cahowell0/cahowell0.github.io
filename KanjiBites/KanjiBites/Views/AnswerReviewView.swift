import SwiftUI

struct AnswerReviewView: View {
    let card: Card
    let outcome: StudyOutcome
    let userDrawingImage: UIImage?
    let recognizedText: String
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                outcomeBadge

                HStack(alignment: .top, spacing: 32) {
                    VStack(spacing: 10) {
                        Text("Your Writing")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let img = userDrawingImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 320, maxHeight: 220)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.secondary.opacity(0.3))
                                )
                        } else {
                            Text("No drawing captured")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: 320, minHeight: 100)
                        }

                        if !recognizedText.isEmpty {
                            Text("Recognized: \(recognizedText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(spacing: 10) {
                        Text("Expected")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(card.kanjiAnswer)
                            .font(.system(size: 72))

                        Text(card.kanaReading)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(card.englishPrompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(16)

                VStack(spacing: 4) {
                    Text("Next review")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(card.dueDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                }

                Button("Next Card", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .font(.title3)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    @ViewBuilder
    private var outcomeBadge: some View {
        let (label, color): (String, Color) = {
            switch outcome {
            case .correct:               return ("Correct", .green)
            case .correctKanaHint:       return ("Correct — kana hint used", .yellow)
            case .correctHeavyPenalty:   return ("Correct — 3rd attempt", .orange)
            case .incorrect:             return ("Incorrect", .red)
            }
        }()

        Text(label)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(14)
    }
}
