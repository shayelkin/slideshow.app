import SwiftUI
import NSViewProxy

extension View {
    @ViewBuilder
    func navigationDocument(_ url: URL?) -> some View {
        if let url {
            self.navigationDocument(url)
        } else {
            self
        }
    }
}

struct ContentView: View {
    @State private var state = SlideshowState()
    @FocusState private var hasFocus
    @State private var window: NSWindow?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch state.displayContent {
            case .image(let url):
                AsyncImage(url: url) { phase in
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
            case .message(let text):
                Text(text)
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(state.windowTitle)
        .navigationDocument(state.folder)
        // Focus needs to be after navigationTitle, or it won't work.
        .focusable()
        .focused($hasFocus)
        .proxy(to: .window) { window in
            guard !state.inTestCase else { return }

            DispatchQueue.main.async {
                self.window = window
            }

            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            } else {
                onFullScreen()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { notification in
            guard let window = self.window,
                let noteWindow = notification.object as? NSWindow,
                window === noteWindow else { return }
           onFullScreen()
        }
        .onKeyPress { press in
            switch press.key {
            case .delete, .upArrow, .leftArrow:
                state.navigate(.previous)
            case .space, .downArrow, .rightArrow:
                state.navigate(.next)
            case .return:
                if !state.hasFolder || press.modifiers.contains(.command) {
                    showOpenDialog()
                }
                // Else will still return .handled, which is ok: it should be a no-op.
            case .escape:
                closeWindow()
            default:
                return .ignored
            }
            return .handled
        }
        .onOpenURL { url in
            guard url.isDirectory else {
                print("onOpenURL called with not a directory \(url)"); return
            }
            state.folder = url
        }
    }

    func closeWindow() {
        guard let window = self.window else { return }
        window.close()
    }

    func onFullScreen() {
        self.hasFocus = true
        if !state.hasFolder {
            showOpenDialog()
        }
    }

    func showOpenDialog() {
        assert(!state.inTestCase)

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.begin() { response in
            if response == .OK, let url = panel.url {
                state.folder = url
            }
        }
    }
}

#Preview {
    ContentView()
}
