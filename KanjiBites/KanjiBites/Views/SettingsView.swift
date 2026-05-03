import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]

    @AppStorage("dailyNewCardLimit") private var dailyNewCardLimit: Int = 20
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("Study Limits") {
                Stepper(
                    "Daily new card limit: \(dailyNewCardLimit)",
                    value: $dailyNewCardLimit,
                    in: 1...200
                )
            }

            Section("Danger Zone") {
                Button("Reset All Progress", role: .destructive) {
                    showingResetConfirmation = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset All Progress?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) { resetAllProgress() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all card intervals, ease factors, and review history. Your cards and decks will be kept.")
        }
    }

    private func resetAllProgress() {
        for deck in decks {
            for card in deck.cards {
                card.intervalDays = 1
                card.easeFactor = 2.5
                card.dueDate = Date()
                for entry in card.reviewHistory {
                    modelContext.delete(entry)
                }
                card.reviewHistory = []
            }
        }
        try? modelContext.save()
    }
}
