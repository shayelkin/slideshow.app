import SwiftUI

protocol OpenPanelProvider: Sendable {
    @MainActor
    func pickFolder() async -> URL?
}

struct RealOpenPanelProvider: OpenPanelProvider {
    @MainActor
    func pickFolder() async -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let response = await panel.begin()
        if response == .OK, let url = panel.url {
            return url
        }
        return nil
    }
}
