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
                    } else {
                        // Try to restore last opened file if no file was passed
                        _ = appState.restoreLastOpenedFile()
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
                    appState.saveSettings()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button(appState.focusMode ? "Exit Focus Mode" : "Enter Focus Mode") {
                    appState.toggleFocusMode()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Divider()

                Menu("Theme") {
                    Button("Light") { appState.theme = .light; appState.saveSettings() }
                    Button("Dark") { appState.theme = .dark; appState.saveSettings() }
                    Button("Sepia") { appState.theme = .sepia; appState.saveSettings() }
                }

                Menu("Line Height") {
                    ForEach(LineHeight.allCases, id: \.self) { height in
                        Button(height.label) { appState.lineHeight = height; appState.saveSettings() }
                    }
                }

                Divider()

                Button("Increase Font Size") {
                    appState.fontSize = min(24, appState.fontSize + 1)
                    appState.saveSettings()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Decrease Font Size") {
                    appState.fontSize = max(12, appState.fontSize - 1)
                    appState.saveSettings()
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

    // View settings - optimized defaults for reading (persisted via @AppStorage in init)
    @Published var viewMode: ViewMode = .read
    @Published var theme: AppTheme = .dark
    @Published var fontSize: CGFloat = 17
    @Published var contentWidth: CGFloat = 720
    @Published var lineHeight: LineHeight = .normal
    @Published var showTOC: Bool = false
    @Published var scrollToHeadingId: String? = nil
    @Published var searchQuery: String = ""
    @Published var focusMode: Bool = false

    // MARK: - Document Statistics (computed)
    var wordCount: Int {
        markdownText.split { $0.isWhitespace || $0.isNewline }.count
    }

    var characterCount: Int {
        markdownText.count
    }

    var characterCountNoSpaces: Int {
        markdownText.filter { !$0.isWhitespace && !$0.isNewline }.count
    }

    var readingTime: String {
        let words = wordCount
        let minutes = max(1, Int(ceil(Double(words) / 200.0)))
        return minutes == 1 ? "1 min read" : "\(minutes) min read"
    }

    // MARK: - Performance: Debounce timers and background queues
    private var renderDebounceTimer: DispatchWorkItem?
    private var tocDebounceTimer: DispatchWorkItem?
    private var lastMarkdownHash: Int = 0
    private var lastTOCHash: Int = 0

    // Background queue for parsing (QoS: userInitiated for responsive updates)
    private let parsingQueue = DispatchQueue(label: "com.markdownopener.parsing", qos: .userInitiated)

    // Debounce delay in seconds
    private let renderDebounceDelay: Double = 0.15  // 150ms for render
    private let tocDebounceDelay: Double = 0.20     // 200ms for TOC

    // MARK: - UserDefaults Keys for State Persistence
    private enum StorageKeys {
        static let theme = "app.theme"
        static let fontSize = "app.fontSize"
        static let contentWidth = "app.contentWidth"
        static let lineHeight = "app.lineHeight"
        static let showTOC = "app.showTOC"
        static let viewMode = "app.viewMode"
        static let lastFileURL = "app.lastFileURL"
        static let lastFileBookmark = "app.lastFileBookmark"
    }

    init() {
        // Restore persisted settings
        let defaults = UserDefaults.standard

        if let themeRaw = defaults.string(forKey: StorageKeys.theme),
           let savedTheme = AppTheme(rawValue: themeRaw) {
            self.theme = savedTheme
        }

        if defaults.object(forKey: StorageKeys.fontSize) != nil {
            self.fontSize = CGFloat(defaults.double(forKey: StorageKeys.fontSize))
        }

        if defaults.object(forKey: StorageKeys.contentWidth) != nil {
            self.contentWidth = CGFloat(defaults.double(forKey: StorageKeys.contentWidth))
        }

        if let lineHeightRaw = defaults.string(forKey: StorageKeys.lineHeight),
           let savedLineHeight = LineHeight(rawValue: lineHeightRaw) {
            self.lineHeight = savedLineHeight
        }

        if defaults.object(forKey: StorageKeys.showTOC) != nil {
            self.showTOC = defaults.bool(forKey: StorageKeys.showTOC)
        }

        if let viewModeRaw = defaults.string(forKey: StorageKeys.viewMode),
           let savedViewMode = ViewMode(rawValue: viewModeRaw) {
            self.viewMode = savedViewMode
        }

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
        - **Focus Mode** - Press `Shift+Cmd+F` for distraction-free writing
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
        | ⇧⌘F | Focus Mode |
        | ⌘+ | Increase font |
        | ⌘- | Decrease font |
        | Esc | Exit Focus Mode |

        ## Tips

        - Click any heading in the TOC to jump to it
        - Use Sepia theme for reduced eye strain
        - Adjust line height for comfortable reading
        - Links open in your default browser
        """
        self.markdownText = defaultContent
        self.debouncedMarkdown = defaultContent
        self.headings = Self.extractHeadings(from: defaultContent)
        self.lastMarkdownHash = defaultContent.hashValue
        self.lastTOCHash = defaultContent.hashValue

        // Set up observers for persisting changes
        setupPersistenceObservers()
    }

    // MARK: - Settings Persistence
    private func setupPersistenceObservers() {
        // We use didSet-style saving by calling saveSettings() in appropriate places
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(theme.rawValue, forKey: StorageKeys.theme)
        defaults.set(Double(fontSize), forKey: StorageKeys.fontSize)
        defaults.set(Double(contentWidth), forKey: StorageKeys.contentWidth)
        defaults.set(lineHeight.rawValue, forKey: StorageKeys.lineHeight)
        defaults.set(showTOC, forKey: StorageKeys.showTOC)
        defaults.set(viewMode.rawValue, forKey: StorageKeys.viewMode)
    }

    func saveLastOpenedFile(_ url: URL) {
        // Save file URL as string for display/reference
        UserDefaults.standard.set(url.path, forKey: StorageKeys.lastFileURL)

        // Save security-scoped bookmark for reopening
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: StorageKeys.lastFileBookmark)
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    func restoreLastOpenedFile() -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: StorageKeys.lastFileBookmark) else {
            return false
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Bookmark is stale, try to refresh it
                saveLastOpenedFile(url)
            }

            // Access the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                return false
            }

            openFile(url)
            return true
        } catch {
            print("Failed to restore bookmark: \(error)")
            return false
        }
    }

    var lastOpenedFilePath: String? {
        UserDefaults.standard.string(forKey: StorageKeys.lastFileURL)
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

    // MARK: - Debounced TOC Update (Background Thread)
    private func scheduleTOCUpdate() {
        // Cancel previous timer
        tocDebounceTimer?.cancel()

        // Capture current text for background processing
        let currentText = self.markdownText
        let textHash = currentText.hashValue

        // Skip if text hasn't changed
        guard textHash != lastTOCHash else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Parse on background thread
            self.parsingQueue.async {
                let newHeadings = Self.extractHeadings(from: currentText)

                // Update on main thread
                DispatchQueue.main.async {
                    // Double-check we still need this update
                    guard self.lastTOCHash != textHash else { return }
                    self.lastTOCHash = textHash

                    // Only update if headings changed
                    if newHeadings != self.headings {
                        self.headings = newHeadings
                    }
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
        var inCodeBlock = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Track fenced code block state
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock = !inCodeBlock
                continue
            }

            // Skip content inside code blocks
            if inCodeBlock {
                continue
            }

            if trimmed.hasPrefix("#") {
                var level = 0
                for char in trimmed {
                    if char == "#" { level += 1 }
                    else { break }
                }
                if level >= 1 && level <= 6 {
                    let afterHashes = String(trimmed.dropFirst(level))
                    // Valid markdown heading must have space after # symbols
                    // (e.g., "# Heading" not "#1 item")
                    guard afterHashes.hasPrefix(" ") || afterHashes.isEmpty else {
                        continue
                    }
                    let text = afterHashes.trimmingCharacters(in: .whitespaces)
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
        saveSettings()
    }

    func toggleFocusMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            focusMode.toggle()
        }
        // Auto-switch to edit mode when entering focus mode (for writing)
        if focusMode && viewMode == .read {
            viewMode = .edit
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
            let contentHash = content.hashValue

            // Update both immediately for file opens (not typing)
            markdownText = content
            debouncedMarkdown = content
            lastMarkdownHash = contentHash
            lastTOCHash = contentHash

            // Parse headings on background for large files, sync for small files
            if content.count > 50000 {
                // Large file: parse on background thread
                parsingQueue.async { [weak self] in
                    let newHeadings = Self.extractHeadings(from: content)
                    DispatchQueue.main.async {
                        self?.headings = newHeadings
                    }
                }
            } else {
                // Small file: parse immediately
                headings = Self.extractHeadings(from: content)
            }

            currentFileURL = url
            windowTitle = url.lastPathComponent

            // Save as last opened file for restoration
            saveLastOpenedFile(url)

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
