import Cocoa

enum Theme {
    case light
    case dark

    init() {
        self = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark" ? .dark : .light
    }
}

func update() {
    let theme = Theme()

    let kitty = Kitty()
    kitty.setTheme(theme: theme)

    let neovim = NeovimRPC()
    neovim.set_option_value(name: "background", value: theme == .dark ? "dark" : "light")
}

DistributedNotificationCenter.default.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil) { _ in update() }

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didWakeNotification,
    object: nil,
    queue: nil) { _ in update() }

RunLoop.current.perform {
    update()
}

print("Watching for changes...")
NSApplication.shared.run()
