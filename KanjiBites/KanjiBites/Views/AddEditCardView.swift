import SwiftUI
import SwiftData

struct AddEditCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var card: Card? = nil

    @State private var englishPrompt = ""
    @State private var kanaReading = ""
    @State private var kanjiAnswer = ""

    var isEditing: Bool { card != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("English Prompt") {
                    TextField("e.g. Natural language processing", text: $englishPrompt)
                }
                Section("Kana Reading") {
                    TextField("e.g. しぜんげんごしょり", text: $kanaReading)
                        .font(.title3)
                }
                Section("Kanji Answer") {
                    TextField("e.g. 自然言語処理", text: $kanjiAnswer)
                        .font(.title3)
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(
                            englishPrompt.trimmingCharacters(in: .whitespaces).isEmpty ||
                            kanjiAnswer.trimmingCharacters(in: .whitespaces).isEmpty
                        )
                }
            }
            .onAppear {
                if let card {
                    englishPrompt = card.englishPrompt
                    kanaReading = card.kanaReading
                    kanjiAnswer = card.kanjiAnswer
                }
            }
        }
    }

    private func save() {
        let trimmedEnglish = englishPrompt.trimmingCharacters(in: .whitespaces)
        let trimmedKana = kanaReading.trimmingCharacters(in: .whitespaces)
        let trimmedKanji = kanjiAnswer.trimmingCharacters(in: .whitespaces)

        if let card {
            card.englishPrompt = trimmedEnglish
            card.kanaReading = trimmedKana
            card.kanjiAnswer = trimmedKanji
        } else {
            let newCard = Card(
                englishPrompt: trimmedEnglish,
                kanaReading: trimmedKana,
                kanjiAnswer: trimmedKanji,
                deck: deck
            )
            modelContext.insert(newCard)
            deck.cards.append(newCard)
        }
        try? modelContext.save()
        dismiss()
    }
}
