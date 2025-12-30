import SwiftUI

enum NavigationAction {
    case previous
    case next
}

enum DisplayContent {
    case image(URL)
    case message(String)
}

@Observable
final class Controller {
    private(set) var imageFiles: [URL] = []
    private(set) var currentIndex = 0
    private(set) var folderSelected = false
    private(set) var lastError: String?

    var displayContent: DisplayContent {
        if !folderSelected {
            return .message("Press \u{21B5} to open a folder")
        }
        if imageFiles.isEmpty {
            return .message(lastError ?? "No images found in folder")
        }
        return .image(imageFiles[currentIndex])
    }

    var currentImage: URL? {
        imageFiles.isEmpty ? nil : imageFiles[currentIndex]
    }

    func handleKeyPress(key: KeyEquivalent, modifiers: EventModifiers) -> Bool {
        switch key {
        case .delete, .upArrow, .leftArrow:
            navigate(.previous)
            return true
        case .space, .downArrow, .rightArrow:
            navigate(.next)
            return true
        case .return:
            return selectFolder(modifiers.contains(.command))
        case .escape:
            NSApplication.shared.terminate(nil)
            return true
        default:
        return false
        }
    }

    func selectFolder(_ force: Bool) -> Bool {
        if folderSelected && !force {
            return false
        }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
        }
        return true
    }

    // MARK: - Internal (testable)

    func navigate(_ action: NavigationAction) {
        guard !imageFiles.isEmpty else { return }
        
        switch action {
        case .previous:
            currentIndex -= 1
            if currentIndex < 0 {
                currentIndex = imageFiles.count - 1
            }
        case .next:
            currentIndex += 1
            if currentIndex >= imageFiles.count {
                currentIndex = 0
            }
        }
        
        assert(0 <= currentIndex)
        assert(currentIndex < imageFiles.count)
    }

    func loadImages(from folder: URL) {
        assert(folder.isDirectory)

        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]

        lastError = nil
        currentIndex = 0
        imageFiles = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )

            imageFiles = contents
                .filter { url in
                    imageExtensions.contains(url.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            lastError = error.localizedDescription
        }
        
        folderSelected = true
    }
}
