import SwiftUI
import SwiftData

@main
struct KanjiBitesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // List all three model types explicitly to avoid "model not found in container" crash
        .modelContainer(for: [Deck.self, Card.self, ReviewEntry.self])
    }
}
