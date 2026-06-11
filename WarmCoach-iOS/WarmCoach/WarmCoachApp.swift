import SwiftUI

@main
struct WarmCoachApp: App {
    @StateObject private var store = CoachStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
