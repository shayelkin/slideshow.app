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
    private let fs: FileSystemProvider

    private(set) var folder: URL?

    init(fs: FileSystemProvider = RealFileSystemProvider()) {
        self.fs = fs
    }

    // Getters are internal, but made visible for tests
    private(set) var images: [URL] = []
    private(set) var currentIndex = 0
    private(set) var lastError: String?

    var hasFolder: Bool { folder != nil }

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

    @MainActor
    func loadFolder(_ url: URL) async {
        folder = url

        images = []
        currentIndex = 0
        lastError = nil

        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        let fs = self.fs

        let result = await Task.detached {
            do {
                let contents = try fs.contentsOfDirectory(at: url)

                let loadedImages = contents
                    .filter { url in
                        imageExtensions.contains(url.pathExtension.lowercased())
                    }
                    .sorted {
                        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                    }
                return Result<[URL], Error>.success(loadedImages)
            } catch {
                return Result<[URL], Error>.failure(error)
            }
        }.value

        // Ensure we are still loading the same folder
        guard folder == url else { return }

        switch result {
        case .success(let loadedImages):
            images = loadedImages
        case .failure(let error):
            assert(images.isEmpty)
            lastError = error.localizedDescription
        }
    }
}
