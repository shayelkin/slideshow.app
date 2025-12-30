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

            if window.styleMask.contains(.fullScreen) == false {
                window.toggleFullScreen(nil)
            }
            // It can take a while for the window to go full screen. Launching the open
            // dialog before that could have the dialog on another screen.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.hasFocus = true
                if !state.hasFolder {
                    showOpenDialog()
                }
            }
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
            case .escape:
                // FIXME: use the actual window, rather than assuming it's keyWindow
                NSApplication.shared.keyWindow?.close()
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
