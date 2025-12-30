import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var images: [URL] = []
    @State private var currentIndex = 0
    @State private var folderSelected = false
    @State private var lastError: LocalizedStringKey?
    @FocusState private var hasFocus

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if folderSelected {
                if images.isEmpty {
                    Text(lastError ?? "No images found in folder")
                        .foregroundColor(.white)
                        .font(.title)
                } else {
                    AsyncImage(url: images[currentIndex]) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Text("Failed to load image")
                                .foregroundColor(.white)
                                .font(.title)
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            } else {
                Text("Press \u{21B5} to open a folder")
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focused($hasFocus)
        .onKeyPress { press in
            handleKeyPress(press)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.hasFocus = true
                if !folderSelected {
                    selectFolder()
                }
            }
        }
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .delete:
            fallthrough
        case .upArrow:
            fallthrough
        case .leftArrow:
            currentIndex -= 1
            if currentIndex < 0 {
                currentIndex = images.count - 1
            }
            return .handled
        case .space:
            fallthrough
        case .downArrow:
            fallthrough
        case .rightArrow:
            currentIndex += 1
            if currentIndex == images.count {
                currentIndex = 0
            }
            return .handled
        case .escape:
            NSApplication.shared.terminate(nil)
            return .handled
        case .return:
            if !folderSelected || press.modifiers.contains(.command) {
                selectFolder()
            }
            return .handled
        default:
            return .ignored
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
            folderSelected = true
        }
    }

    private func loadImages(from folder: URL) {
        assert(folder.isDirectory)

        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]

        do {
            lastError = nil
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )

            images = contents
                .filter { url in
                    imageExtensions.contains(url.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

            currentIndex = 0
        } catch {
            lastError = LocalizedStringKey(stringLiteral: error.localizedDescription)
            images = []
        }
    }
}

#Preview {
    ContentView()
}
