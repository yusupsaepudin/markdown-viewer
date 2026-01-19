import SwiftUI

@main
struct MarkdownOpenerApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.openFile(url)
                }
                .onAppear {
                    // Handle file opened via double-click or drag
                    appDelegate.appState = appState
                    if let url = appDelegate.pendingFileURL {
                        appState.openFile(url)
                        appDelegate.pendingFileURL = nil
                    }
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

            // Find menu
            CommandGroup(replacing: .textEditing) {
                Button("Find...") {
                    NotificationCenter.default.post(name: .toggleSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Toggle Read/Edit Mode") {
                    appState.toggleViewMode()
                }
                .keyboardShortcut("e", modifiers: .command)

                Button("Toggle Table of Contents") {
                    withAnimation {
                        appState.showTOC.toggle()
                    }
                }
                .keyboardShortcut("t", modifiers: .command)

                Divider()

                Menu("Theme") {
                    Button("Light") { appState.theme = .light }
                    Button("Dark") { appState.theme = .dark }
                    Button("Sepia") { appState.theme = .sepia }
                }

                Menu("Line Height") {
                    ForEach(LineHeight.allCases, id: \.self) { height in
                        Button(height.label) { appState.lineHeight = height }
                    }
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

// MARK: - App Delegate for handling file opens
class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?
    var pendingFileURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if let appState = appState {
            appState.openFile(url)
        } else {
            pendingFileURL = url
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // File opening is handled via application(_:open:)
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

// MARK: - Line Height (Research-based optimal values)
enum LineHeight: String, CaseIterable {
    case compact = "1.5"    // Quick scanning
    case normal = "1.7"     // Optimal for most reading
    case relaxed = "1.9"    // Comfortable for long sessions
    case spacious = "2.2"   // Low vision / very long sessions

    var value: CGFloat {
        CGFloat(Double(rawValue) ?? 1.7)
    }

    var label: String {
        switch self {
        case .compact: return "Compact (1.5)"
        case .normal: return "Normal (1.7) - Recommended"
        case .relaxed: return "Relaxed (1.9)"
        case .spacious: return "Spacious (2.2)"
        }
    }

    var shortLabel: String {
        switch self {
        case .compact: return "Compact"
        case .normal: return "Normal"
        case .relaxed: return "Relaxed"
        case .spacious: return "Spacious"
        }
    }
}

// MARK: - Heading (for TOC)
struct Heading: Identifiable, Equatable {
    let id: String
    let level: Int
    let text: String

    var indent: CGFloat {
        CGFloat((level - 1) * 12)
    }
}

// MARK: - App State
class AppState: ObservableObject {
    // Raw markdown text (updates immediately for responsive editing)
    @Published var markdownText: String = "" {
        didSet {
            scheduleRenderUpdate()
            scheduleTOCUpdate()
        }
    }

    // Debounced markdown for rendering (updates after 150ms pause)
    @Published var debouncedMarkdown: String = ""

    // Cached headings for TOC (updates after 200ms pause)
    @Published var headings: [Heading] = []

    @Published var currentFileURL: URL?
    @Published var windowTitle: String = "Markdown Opener"

    // View settings - optimized defaults for reading
    @Published var viewMode: ViewMode = .read
    @Published var theme: AppTheme = .dark
    @Published var fontSize: CGFloat = 17
    @Published var contentWidth: CGFloat = 720
    @Published var lineHeight: LineHeight = .normal
    @Published var showTOC: Bool = false
    @Published var scrollToHeadingId: String? = nil
    @Published var searchQuery: String = ""

    // MARK: - Performance: Debounce timers
    private var renderDebounceTimer: DispatchWorkItem?
    private var tocDebounceTimer: DispatchWorkItem?
    private var lastMarkdownHash: Int = 0

    // Debounce delay in milliseconds
    private let renderDebounceDelay: Double = 0.15  // 150ms for render
    private let tocDebounceDelay: Double = 0.20     // 200ms for TOC

    init() {
        // Set default content
        let defaultContent = """
        # Welcome to Markdown Opener

        A fast, native markdown viewer for macOS.

        ## Features

        - **Live preview** as you type
        - Syntax highlighting for code blocks
        - **Read/Edit toggle** - Press `Cmd+E`
        - **Table of Contents** - Press `Cmd+T`
        - **Search** - Press `Cmd+F`
        - **Theme options** - Light, Dark, Sepia
        - **Typography controls** - Font size, line height, width

        ## Reading Comfort

        This app uses research-based typography settings:

        - **Line height 1.7** is optimal for most reading
        - **Content width ~720px** (65-75 characters per line)
        - **System font** for best legibility

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

        ## Keyboard Shortcuts

        | Shortcut | Action |
        |----------|--------|
        | ⌘E | Toggle Read/Edit |
        | ⌘T | Toggle TOC |
        | ⌘F | Search |
        | ⌘+ | Increase font |
        | ⌘- | Decrease font |

        ## Tips

        - Click any heading in the TOC to jump to it
        - Use Sepia theme for reduced eye strain
        - Adjust line height for comfortable reading
        - Links open in your default browser
        """
        self.markdownText = defaultContent
        self.debouncedMarkdown = defaultContent
        self.headings = Self.extractHeadings(from: defaultContent)
    }

    // MARK: - Debounced Render Update
    private func scheduleRenderUpdate() {
        // Cancel previous timer
        renderDebounceTimer?.cancel()

        // In read mode, update immediately for instant feedback when switching modes
        // In edit mode, debounce to avoid excessive re-renders while typing
        let delay = viewMode == .edit ? renderDebounceDelay : 0

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let newHash = self.markdownText.hashValue
            // Only update if content actually changed
            if newHash != self.lastMarkdownHash {
                self.lastMarkdownHash = newHash
                DispatchQueue.main.async {
                    self.debouncedMarkdown = self.markdownText
                }
            }
        }

        renderDebounceTimer = workItem

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        } else {
            workItem.perform()
        }
    }

    // MARK: - Debounced TOC Update
    private func scheduleTOCUpdate() {
        // Cancel previous timer
        tocDebounceTimer?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let newHeadings = Self.extractHeadings(from: self.markdownText)
            // Only update if headings changed
            if newHeadings != self.headings {
                DispatchQueue.main.async {
                    self.headings = newHeadings
                }
            }
        }

        tocDebounceTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + tocDebounceDelay, execute: workItem)
    }

    // MARK: - Static heading extraction (for caching)
    private static func extractHeadings(from text: String) -> [Heading] {
        let lines = text.components(separatedBy: .newlines)
        var result: [Heading] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                var level = 0
                for char in trimmed {
                    if char == "#" { level += 1 }
                    else { break }
                }
                if level >= 1 && level <= 6 {
                    let text = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                    if !text.isEmpty {
                        let id = text.lowercased()
                            .replacingOccurrences(of: " ", with: "-")
                            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                        result.append(Heading(id: id, level: level, text: text))
                    }
                }
            }
        }
        return result
    }

    func toggleViewMode() {
        viewMode = viewMode == .edit ? .read : .edit
        // Force immediate update when switching to read mode
        if viewMode == .read {
            debouncedMarkdown = markdownText
        }
    }

    func scrollToHeading(_ heading: Heading) {
        scrollToHeadingId = heading.id
        // Reset after a short delay to allow re-clicking same heading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scrollToHeadingId = nil
        }
    }

    func openFile(_ url: URL) {
        // Request access to the file
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            // Update both immediately for file opens (not typing)
            markdownText = content
            debouncedMarkdown = content
            headings = Self.extractHeadings(from: content)
            lastMarkdownHash = content.hashValue

            currentFileURL = url
            windowTitle = url.lastPathComponent

            // Update window title
            DispatchQueue.main.async {
                NSApplication.shared.windows.first?.title = url.lastPathComponent
            }
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
