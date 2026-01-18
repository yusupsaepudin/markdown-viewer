import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            // Main content
            if appState.viewMode == .read {
                readModeView
            } else {
                editModeView
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(backgroundColor)
    }

    // MARK: - Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Mode toggle
            Picker("Mode", selection: $appState.viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            Divider()
                .frame(height: 20)

            // Theme picker
            Menu {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        appState.theme = theme
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                            if appState.theme == theme {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: themeIcon)
                    Text(appState.theme.rawValue)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 80)

            Divider()
                .frame(height: 20)

            // Font size controls
            HStack(spacing: 8) {
                Button {
                    appState.fontSize = max(12, appState.fontSize - 1)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .buttonStyle(.borderless)

                Text("\(Int(appState.fontSize))px")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 40)

                Button {
                    appState.fontSize = min(24, appState.fontSize + 1)
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .buttonStyle(.borderless)
            }

            Divider()
                .frame(height: 20)

            // Content width slider
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.and.right")
                    .foregroundColor(.secondary)
                Slider(value: $appState.contentWidth, in: 500...1200, step: 20)
                    .frame(width: 100)
            }

            Spacer()

            // Keyboard hint
            Text("⌘E toggle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Read Mode (Full Preview)
    private var readModeView: some View {
        WebPreviewView(
            markdown: appState.markdownText,
            theme: appState.theme,
            fontSize: appState.fontSize,
            contentWidth: appState.contentWidth
        )
    }

    // MARK: - Edit Mode (Split View)
    private var editModeView: some View {
        HSplitView {
            // Editor pane
            VStack(spacing: 0) {
                HStack {
                    Text("Editor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

                TextEditor(text: $appState.markdownText)
                    .font(.system(size: appState.fontSize - 2, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(editorBackgroundColor)
            }
            .frame(minWidth: 250)

            // Preview pane
            VStack(spacing: 0) {
                HStack {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

                WebPreviewView(
                    markdown: appState.markdownText,
                    theme: appState.theme,
                    fontSize: appState.fontSize,
                    contentWidth: appState.contentWidth
                )
            }
            .frame(minWidth: 250)
        }
    }

    // MARK: - Theme Helpers
    private var themeIcon: String {
        switch appState.theme {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .sepia: return "book"
        }
    }

    private var backgroundColor: Color {
        switch appState.theme {
        case .light: return Color(NSColor.windowBackgroundColor)
        case .dark: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .sepia: return Color(red: 0.96, green: 0.94, blue: 0.88)
        }
    }

    private var editorBackgroundColor: Color {
        switch appState.theme {
        case .light: return Color(NSColor.textBackgroundColor)
        case .dark: return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .sepia: return Color(red: 0.98, green: 0.96, blue: 0.90)
        }
    }
}
