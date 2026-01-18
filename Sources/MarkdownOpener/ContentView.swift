import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isToolbarVisible = true

    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            mainContent
                .padding(.top, isToolbarVisible ? 52 : 0)

            // Floating toolbar
            if isToolbarVisible {
                toolbar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(backgroundColor)
        .animation(.easeInOut(duration: 0.2), value: isToolbarVisible)
        .onHover { hovering in
            // Auto-hide toolbar logic could go here
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if appState.viewMode == .read {
            // Read mode: rendered preview
            WebPreviewView(
                markdown: appState.markdownText,
                theme: appState.theme,
                fontSize: appState.fontSize,
                contentWidth: appState.contentWidth
            )
        } else {
            // Edit mode: single editable text view (no split)
            editableMarkdownView
        }
    }

    // MARK: - Editable Markdown View (Single Pane)
    private var editableMarkdownView: some View {
        ScrollView {
            TextEditor(text: $appState.markdownText)
                .font(.system(size: appState.fontSize, design: .monospaced))
                .scrollContentBackground(.hidden)
                .frame(maxWidth: appState.contentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .background(backgroundColor)
    }

    // MARK: - Minimal Floating Toolbar
    private var toolbar: some View {
        HStack(spacing: 16) {
            // Mode toggle (clean, no label)
            Picker("", selection: $appState.viewMode) {
                Text("Read").tag(ViewMode.read)
                Text("Edit").tag(ViewMode.edit)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .labelsHidden()

            Spacer()
                .frame(width: 8)

            // Theme button
            Menu {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            appState.theme = theme
                        }
                    } label: {
                        HStack {
                            Image(systemName: iconForTheme(theme))
                            Text(theme.rawValue)
                            if appState.theme == theme {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: themeIcon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Theme")

            // Font size
            HStack(spacing: 4) {
                Button {
                    appState.fontSize = max(12, appState.fontSize - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Decrease font size (⌘-)")

                Text("\(Int(appState.fontSize))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                Button {
                    appState.fontSize = min(24, appState.fontSize + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Increase font size (⌘+)")
            }

            // Width control (simplified)
            Menu {
                Button("Narrow (560px)") { appState.contentWidth = 560 }
                Button("Medium (720px)") { appState.contentWidth = 720 }
                Button("Wide (900px)") { appState.contentWidth = 900 }
                Button("Full (1100px)") { appState.contentWidth = 1100 }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Content width")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(toolbarBackground)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Theme Helpers
    private var themeIcon: String {
        switch appState.theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        }
    }

    private func iconForTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .sepia: return "book"
        }
    }

    private var backgroundColor: Color {
        switch appState.theme {
        case .light: return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .sepia: return Color(red: 0.97, green: 0.94, blue: 0.88)
        }
    }

    private var toolbarBackground: Color {
        switch appState.theme {
        case .light: return Color(red: 1, green: 1, blue: 1).opacity(0.95)
        case .dark: return Color(red: 0.18, green: 0.18, blue: 0.20).opacity(0.95)
        case .sepia: return Color(red: 0.99, green: 0.96, blue: 0.90).opacity(0.95)
        }
    }
}
