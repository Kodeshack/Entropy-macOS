import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let window = sender.windows.first else {
            return true
        }

        if flag {
            window.orderFront(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }

        return true
    }
}
