import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var deck: Deck

    @State private var showingAddCard = false
    @State private var cardToEdit: Card? = nil
    @State private var showingStudy = false
    @State private var showingRename = false
    @State private var renameText = ""

    private var sortedCards: [Card] {
        deck.cards.sorted { $0.englishPrompt < $1.englishPrompt }
    }

    private var dueCount: Int { deck.dueCardCount }

    var body: some View {
        List {
            if deck.cards.isEmpty {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "rectangle.stack.badge.plus",
                    description: Text("Tap + to add your first card.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(sortedCards) { card in
                    Button {
                        cardToEdit = card
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(card.englishPrompt)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("\(card.kanaReading) · \(card.kanjiAnswer)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Due: \(card.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(card.dueDate <= Date() ? .red : .secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .onDelete(perform: deleteCards)
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Card", systemImage: "plus") {
                    showingAddCard = true
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Rename Deck") {
                    renameText = deck.name
                    showingRename = true
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    showingStudy = true
                } label: {
                    Label(
                        dueCount == 0 ? "No Cards Due" : "Study Now (\(dueCount) due)",
                        systemImage: "pencil.and.list.clipboard"
                    )
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(dueCount == 0)
                Spacer()
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddEditCardView(deck: deck)
        }
        .sheet(item: $cardToEdit) { card in
            AddEditCardView(deck: deck, card: card)
        }
        .fullScreenCover(isPresented: $showingStudy) {
            StudySessionContainerView(deck: deck)
        }
        .alert("Rename Deck", isPresented: $showingRename) {
            TextField("Deck name", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { deck.name = trimmed }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        let sorted = sortedCards
        for index in offsets {
            modelContext.delete(sorted[index])
        }
        try? modelContext.save()
    }
}
