import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var editorWidth: CGFloat = 400

    var body: some View {
        HSplitView {
            // Editor pane
            VStack(spacing: 0) {
                HStack {
                    Text("Editor")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                TextEditor(text: $appState.markdownText)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
            }
            .frame(minWidth: 250)

            // Preview pane
            VStack(spacing: 0) {
                HStack {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                WebPreviewView(markdown: appState.markdownText)
            }
            .frame(minWidth: 250)
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle(appState.windowTitle)
    }
}
