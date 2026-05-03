import SwiftUI
import PencilKit

// MARK: - Container

/// Created via .fullScreenCover. Owns the ViewModel and routes between sub-screens.
struct StudySessionContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @State private var viewModel: StudySessionViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.sessionEnded {
                    SessionSummaryView(summary: vm.summary) { dismiss() }
                } else if let card = vm.currentCard {
                    if case .result(let outcome) = vm.phase {
                        AnswerReviewView(
                            card: card,
                            outcome: outcome,
                            userDrawingImage: vm.userDrawingImage,
                            recognizedText: vm.recognizedText
                        ) {
                            vm.advanceToNextCard()
                        }
                    } else {
                        StudySessionView(viewModel: vm, card: card)
                    }
                } else {
                    noDueCardsView
                }
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = StudySessionViewModel(cards: deck.cards, modelContext: modelContext)
            }
        }
    }

    private var noDueCardsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("All caught up!")
                .font(.title.weight(.bold))
            Text("No cards are due in this deck right now.")
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Study Screen

struct StudySessionView: View {
    @Bindable var viewModel: StudySessionViewModel
    let card: Card

    @State private var drawing = PKDrawing()
    @State private var canvasSize: CGSize = CGSize(width: 600, height: 400)
    @State private var isRecognizing = false
    @State private var recognitionError: String? = nil
    @State private var showingEndConfirm = false

    private var attemptNumber: Int {
        if case .attempt(let n) = viewModel.phase { return n }
        return 1
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            promptArea
                .padding(.horizontal)
                .padding(.bottom, 8)

            canvasArea

            buttonBar
                .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
        .confirmationDialog("End Session?", isPresented: $showingEndConfirm, titleVisibility: .visible) {
            Button("End Session", role: .destructive) { viewModel.endSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress so far will be saved.")
        }
        // Reset canvas when the card advances
        .onChange(of: viewModel.currentIndex) {
            drawing = PKDrawing()
            recognitionError = nil
        }
    }

    // MARK: Header

    private var headerBar: some View {
        HStack {
            Text("\(viewModel.currentIndex + 1) / \(viewModel.queueCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("End Session") { showingEndConfirm = true }
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: Prompt + Hints

    private var promptArea: some View {
        VStack(spacing: 8) {
            Text(card.englishPrompt)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Attempt \(attemptNumber) of 3")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.hintState.kanaRevealed {
                HStack(spacing: 6) {
                    Image(systemName: "character.ja.hiragana")
                        .foregroundStyle(.blue)
                    Text(card.kanaReading)
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewModel.hintState.kanjiRevealed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.red)
                    Text(card.kanjiAnswer)
                        .font(.title)
                        .foregroundStyle(.red)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let err = recognitionError {
                Text("Recognition error: \(err)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hintState.kanaRevealed)
        .animation(.easeInOut(duration: 0.25), value: viewModel.hintState.kanjiRevealed)
        .padding(.top, 8)
    }

    // MARK: Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            CanvasView(drawing: $drawing)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .onAppear { canvasSize = geo.size }
                .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
        }
    }

    // MARK: Button Bar

    private var buttonBar: some View {
        HStack(spacing: 10) {
            if !viewModel.hintState.kanaRevealed {
                Button("Show Kana") {
                    withAnimation { viewModel.showKana() }
                }
                .buttonStyle(.bordered)
            }

            if !viewModel.hintState.kanjiRevealed {
                Button("Show Kanji") {
                    withAnimation { viewModel.showKanji() }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Spacer()

            Button("Clear", systemImage: "trash") {
                drawing = PKDrawing()
            }
            .buttonStyle(.bordered)
            .labelStyle(.iconOnly)

            Button {
                submitAnswer()
            } label: {
                if isRecognizing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .tint(.white)
                        Text("Recognizing…")
                    }
                    .padding(.horizontal, 8)
                } else {
                    Text("Submit")
                        .padding(.horizontal, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRecognizing || drawing.strokes.isEmpty)
        }
    }

    // MARK: Submit

    private func submitAnswer() {
        guard !drawing.strokes.isEmpty else { return }
        isRecognizing = true
        recognitionError = nil

        let captureSize = canvasSize == .zero
            ? CGSize(width: 600, height: 400)
            : canvasSize
        let snapshot = drawing.image(
            from: CGRect(origin: .zero, size: captureSize),
            scale: UIScreen.main.scale
        )
        viewModel.userDrawingImage = snapshot

        let expectedNormalized = TextNormalizer.normalize(card.kanjiAnswer)

        HandwritingRecognizer.recognize(drawing: drawing, canvasSize: captureSize) { result in
            isRecognizing = false
            switch result {
            case .success(let text):
                viewModel.recognizedText = text
                viewModel.submitAnswer(recognized: text, expectedNormalized: expectedNormalized)
                // Clear canvas on failure so user gets a fresh start
                if case .attempt = viewModel.phase {
                    drawing = PKDrawing()
                }
            case .failure(let error):
                recognitionError = error.localizedDescription
            }
        }
    }
}

// MARK: - Session Summary

struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Session Complete")
                .font(.largeTitle.weight(.bold))

            VStack(alignment: .leading, spacing: 14) {
                summaryRow("Correct", count: summary.correct, color: .green)
                summaryRow("Correct (kana hint)", count: summary.correctKanaHint, color: .yellow)
                summaryRow("Correct (3rd attempt)", count: summary.correctHeavyPenalty, color: .orange)
                summaryRow("Incorrect", count: summary.incorrect, color: .red)

                Divider()

                HStack {
                    Text("Total reviewed")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(summary.total)")
                        .fontWeight(.bold)
                }
            }
            .padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal, 32)

            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .font(.title3)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func summaryRow(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
        }
    }
}
