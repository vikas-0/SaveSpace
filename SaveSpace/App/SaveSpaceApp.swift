import SwiftUI
import Photos

@main
struct SaveSpaceApp: App {
    @StateObject private var photoLibraryViewModel = PhotoLibraryViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibraryViewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .sidebar) {
                Button("Toggle Sidebar") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        with: nil
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
