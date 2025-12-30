import SwiftUI

struct ContentView: View {
    @State private var controller = Controller()
    @FocusState private var hasFocus

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch controller.displayContent {
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
        .focusable()
        .focused($hasFocus)
        .onKeyPress { press in
            controller.handleKeyPress(key: press.key, modifiers: press.modifiers) ? .handled : .ignored
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.hasFocus = true
                controller.selectFolder(false)
            }
        }
    }
}

#Preview {
    ContentView()
}
