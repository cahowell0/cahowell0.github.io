import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdDate, order: .reverse) private var decks: [Deck]

    @State private var showingAddDeck = false
    @State private var newDeckName = ""

    var body: some View {
        List {
            if decks.isEmpty {
                ContentUnavailableView(
                    "No Decks",
                    systemImage: "rectangle.stack",
                    description: Text("Tap + to create your first deck.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(decks) { deck in
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.name)
                                .font(.headline)
                            Text("\(deck.cards.count) cards · \(deck.dueCardCount) due today")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteDecks)
            }
        }
        .navigationTitle("Kanji Bites")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Deck", systemImage: "plus") {
                    showingAddDeck = true
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
        .alert("New Deck", isPresented: $showingAddDeck) {
            TextField("Deck name", text: $newDeckName)
            Button("Create") { createDeck() }
            Button("Cancel", role: .cancel) { newDeckName = "" }
        }
    }

    private func createDeck() {
        let trimmed = newDeckName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let deck = Deck(name: trimmed)
        modelContext.insert(deck)
        try? modelContext.save()
        newDeckName = ""
    }

    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(decks[index])
        }
        try? modelContext.save()
    }
}
