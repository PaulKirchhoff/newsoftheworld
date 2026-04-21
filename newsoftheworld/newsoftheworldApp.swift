import SwiftUI

@main
struct NewsOfTheWorldApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        LanguagePreference.applyAtStartup()
    }

    var body: some Scene {
        Settings { EmptyView() }
    }
}
