import SwiftUI

@main
struct LLMTextRefinerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the dock
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize menu bar manager
        menuBarManager = MenuBarManager()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        menuBarManager = nil
    }
} 