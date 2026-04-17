import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var compositionRoot: CompositionRoot?

    func applicationDidFinishLaunching(_ notification: Notification) {
        compositionRoot = CompositionRoot()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
