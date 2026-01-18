import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isToolbarVisible = true

    var body: some View {
        HStack(spacing: 0) {
            // Table of Contents sidebar
            if appState.showTOC {
                tocSidebar
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Main content area
            ZStack(alignment: .top) {
                mainContent
                    .padding(.top, isToolbarVisible ? 56 : 0)

                if isToolbarVisible {
                    toolbar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(backgroundColor)
        .animation(.easeInOut(duration: 0.2), value: isToolbarVisible)
        .animation(.easeInOut(duration: 0.25), value: appState.showTOC)
    }

    // MARK: - Table of Contents Sidebar
    private var tocSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Contents")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    appState.showTOC = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Close TOC (⌘T)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .opacity(0.5)

            // Headings list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appState.headings) { heading in
                        tocItem(heading)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 220)
        .background(tocBackground)
    }

    private func tocItem(_ heading: Heading) -> some View {
        Button {
            appState.scrollToHeading(heading)
        } label: {
            HStack(spacing: 8) {
                // Level indicator
                RoundedRectangle(cornerRadius: 1)
                    .fill(heading.level == 1 ? accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 2, height: heading.level == 1 ? 16 : 12)

                Text(heading.text)
                    .font(.system(size: heading.level == 1 ? 13 : 12, weight: heading.level == 1 ? .semibold : .regular))
                    .foregroundColor(heading.level == 1 ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.leading, heading.indent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .cornerRadius(4)
    }

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        if appState.viewMode == .read {
            WebPreviewView(
                markdown: appState.markdownText,
                theme: appState.theme,
                fontSize: appState.fontSize,
                contentWidth: appState.contentWidth,
                lineHeight: appState.lineHeight,
                scrollToId: appState.scrollToHeadingId
            )
        } else {
            editableMarkdownView
        }
    }

    // MARK: - Editable Markdown View
    private var editableMarkdownView: some View {
        ScrollView {
            TextEditor(text: $appState.markdownText)
                .font(.system(size: appState.fontSize, design: .monospaced))
                .lineSpacing((appState.lineHeight.value - 1) * appState.fontSize)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: appState.contentWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .background(backgroundColor)
    }

    // MARK: - Floating Toolbar
    private var toolbar: some View {
        HStack(spacing: 12) {
            // TOC toggle
            Button {
                withAnimation { appState.showTOC.toggle() }
            } label: {
                Image(systemName: appState.showTOC ? "list.bullet.indent" : "list.bullet")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("Table of Contents (⌘T)")

            Divider()
                .frame(height: 16)
                .opacity(0.5)

            // Mode toggle
            Picker("", selection: $appState.viewMode) {
                Text("Read").tag(ViewMode.read)
                Text("Edit").tag(ViewMode.edit)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .labelsHidden()

            Spacer()

            // Theme
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
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Theme")

            // Line Height
            Menu {
                ForEach(LineHeight.allCases, id: \.self) { height in
                    Button {
                        appState.lineHeight = height
                    } label: {
                        HStack {
                            Text(height.label)
                            if appState.lineHeight == height {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "text.line.first.and.arrowtriangle.forward")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Line Height")

            // Font size
            HStack(spacing: 4) {
                Button {
                    appState.fontSize = max(12, appState.fontSize - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Decrease font (⌘-)")

                Text("\(Int(appState.fontSize))")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Button {
                    appState.fontSize = min(24, appState.fontSize + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .help("Increase font (⌘+)")
            }

            // Width
            Menu {
                Button { appState.contentWidth = 560 } label: {
                    HStack {
                        Text("Narrow (560)")
                        if appState.contentWidth == 560 { Spacer(); Image(systemName: "checkmark") }
                    }
                }
                Button { appState.contentWidth = 720 } label: {
                    HStack {
                        Text("Medium (720)")
                        if appState.contentWidth == 720 { Spacer(); Image(systemName: "checkmark") }
                    }
                }
                Button { appState.contentWidth = 900 } label: {
                    HStack {
                        Text("Wide (900)")
                        if appState.contentWidth == 900 { Spacer(); Image(systemName: "checkmark") }
                    }
                }
                Button { appState.contentWidth = 1100 } label: {
                    HStack {
                        Text("Full (1100)")
                        if appState.contentWidth == 1100 { Spacer(); Image(systemName: "checkmark") }
                    }
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .help("Content width")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(toolbarBackground)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
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

    private var accentColor: Color {
        switch appState.theme {
        case .light: return .blue
        case .dark: return .blue
        case .sepia: return Color(red: 0.6, green: 0.4, blue: 0.2)
        }
    }

    private var backgroundColor: Color {
        switch appState.theme {
        case .light: return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .dark: return Color(red: 0.11, green: 0.11, blue: 0.12)
        case .sepia: return Color(red: 0.97, green: 0.94, blue: 0.88)
        }
    }

    private var tocBackground: Color {
        switch appState.theme {
        case .light: return Color(red: 0.96, green: 0.96, blue: 0.96)
        case .dark: return Color(red: 0.14, green: 0.14, blue: 0.15)
        case .sepia: return Color(red: 0.94, green: 0.91, blue: 0.84)
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
