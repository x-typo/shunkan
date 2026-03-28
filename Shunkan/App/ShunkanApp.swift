import SwiftUI
import SwiftData

@main
struct ShunkanApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        NotificationCenter.default.post(name: .checkSharedInbox, object: nil)
                    }
                }
        }
        .modelContainer(for: [Book.self, BookCollection.self])
    }
}

extension Notification.Name {
    static let checkSharedInbox = Notification.Name("checkSharedInbox")
}
