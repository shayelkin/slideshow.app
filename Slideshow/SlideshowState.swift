import SwiftUI

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

enum NavigationAction {
    case previous
    case next
}

enum DisplayContent {
    case image(URL)
    case message(String)
}

@Observable
final class SlideshowState {
    private var _folder: URL?
    private(set) var images: [URL] = []
    private(set) var currentIndex = 0 // Getter is internal, made public for testability
    private var lastError: String?

    var hasFolder: Bool { folder != nil }

    // Some UI interactions break when running in CI.
    var inTestCase: Bool { return NSClassFromString("XCTestCase") != nil }

    var folder: URL? {
        get { _folder }
        set {
            guard (newValue != nil) else { return }
            loadFolder(newValue!)
        }
    }

    var displayContent: DisplayContent {
        if let image = currentImage {
            return .image(image)
        }
        if !hasFolder {
            return .message("Press \u{21B5} to open a folder")
        }
        return .message(lastError ?? "No images found in folder")
    }

    var currentImage: URL? {
        return images.isEmpty ? nil : images[currentIndex]
    }

    var windowTitle: String {
        assert(hasFolder || images.isEmpty)
        guard let folder = folder else {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Slideshow"
        }
        if images.isEmpty {
            return folder.lastPathComponent
        }
        return "\(folder.lastPathComponent) [\(currentIndex + 1)/\(images.count)]"
    }

    func navigate(_ action: NavigationAction) {
        guard !images.isEmpty else { return }

        switch action {
        case .previous:
            currentIndex -= 1
            if currentIndex < 0 {
                currentIndex = images.count - 1
            }
        case .next:
            currentIndex += 1
            if currentIndex >= images.count {
                currentIndex = 0
            }
        }

        assert(0 <= currentIndex)
        assert(currentIndex < images.count)
    }

    private func loadFolder(_ url: URL) {
        assert(url.isDirectory)

        _folder = url
        images = []
        currentIndex = 0
        lastError = nil

        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: _folder!,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )

            images = contents
                .filter { url in
                    imageExtensions.contains(url.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            assert(images.isEmpty)
            lastError = error.localizedDescription
        }
    }
}
