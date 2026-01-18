import SwiftUI

@main
struct MarkdownOpenerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.openFile(url)
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Save") {
                    appState.saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appState.currentFileURL == nil)
            }
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.openFile(url)
        }
    }
}

class AppState: ObservableObject {
    @Published var markdownText: String = """
    # Welcome to Markdown Opener

    A fast, native markdown viewer for macOS.

    ## Features

    - **Live preview** as you type
    - Syntax highlighting for code blocks
    - Dark mode support

    ## Code Example

    ```swift
    func greet(name: String) -> String {
        return "Hello, \\(name)!"
    }
    ```

    ```python
    def fibonacci(n):
        if n <= 1:
            return n
        return fibonacci(n-1) + fibonacci(n-2)
    ```

    ## Try it out!

    Start typing in the editor on the left.
    """

    @Published var currentFileURL: URL?
    @Published var windowTitle: String = "Markdown Opener"

    func openFile(_ url: URL) {
        do {
            markdownText = try String(contentsOf: url, encoding: .utf8)
            currentFileURL = url
            windowTitle = url.lastPathComponent
        } catch {
            print("Error opening file: \(error)")
        }
    }

    func saveFile() {
        guard let url = currentFileURL else { return }
        do {
            try markdownText.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving file: \(error)")
        }
    }
}
