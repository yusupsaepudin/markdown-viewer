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

            CommandGroup(after: .toolbar) {
                Button("Toggle Read/Edit Mode") {
                    appState.toggleViewMode()
                }
                .keyboardShortcut("e", modifiers: .command)

                Divider()

                Menu("Theme") {
                    Button("Light") { appState.theme = .light }
                    Button("Dark") { appState.theme = .dark }
                    Button("Sepia") { appState.theme = .sepia }
                }

                Divider()

                Button("Increase Font Size") {
                    appState.fontSize = min(24, appState.fontSize + 1)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    appState.fontSize = max(12, appState.fontSize - 1)
                }
                .keyboardShortcut("-", modifiers: .command)
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

// MARK: - View Mode
enum ViewMode: String, CaseIterable {
    case read = "Read"
    case edit = "Edit"
}

// MARK: - Theme
enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var markdownText: String = """
    # Welcome to Markdown Opener

    A fast, native markdown viewer for macOS.

    ## Features

    - **Live preview** as you type
    - Syntax highlighting for code blocks
    - **Read/Edit toggle** - Press `Cmd+E`
    - **Theme options** - Light, Dark, Sepia
    - **Typography controls** - Adjust font size and width

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

    - Press `Cmd+E` to toggle between Read and Edit mode
    - Use `Cmd++` / `Cmd+-` to adjust font size
    - Click the theme button to switch themes
    """

    @Published var currentFileURL: URL?
    @Published var windowTitle: String = "Markdown Opener"

    // View settings - dark mode default for better eye comfort
    @Published var viewMode: ViewMode = .read
    @Published var theme: AppTheme = .dark
    @Published var fontSize: CGFloat = 17
    @Published var contentWidth: CGFloat = 720

    func toggleViewMode() {
        viewMode = viewMode == .edit ? .read : .edit
    }

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
