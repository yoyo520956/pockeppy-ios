import SwiftUI

@main
struct PocketPyApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
                .preferredColorScheme(.dark)
                .tint(.orange)
        }
    }
}
