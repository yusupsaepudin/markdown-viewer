# MarkdownOpener

A fast, native macOS application for viewing and editing Markdown files with live preview, table of contents navigation, and beautiful typography.

## Features

- **Dual Mode** - Switch between Read mode (rendered HTML) and Edit mode (plain text) with Cmd+E
- **Live Preview** - See changes as you type with debounced rendering for smooth performance
- **Table of Contents** - Auto-generated sidebar with scroll spy that highlights the current section
- **Search** - Find text in your document with Cmd+F
- **Themes** - Light, Dark, and Sepia modes for comfortable reading
- **Typography Controls** - Adjust font size (12-24pt), line height, and content width
- **Syntax Highlighting** - Code blocks highlighted with Highlight.js
- **File Handling** - Open markdown files via Cmd+O, double-click, or drag-and-drop

## Requirements

- macOS 13.0 (Ventura) or later

## Building

```bash
# Clone the repository
git clone https://github.com/yourusername/MarkdownOpener.git
cd MarkdownOpener

# Build release
swift build -c release

# Run directly
swift run MarkdownOpener
```

### Install to Applications

```bash
# Copy binary to app bundle
cp .build/arm64-apple-macosx/release/MarkdownOpener MarkdownOpener.app/Contents/MacOS/

# Install to Applications folder
cp -R MarkdownOpener.app /Applications/
```

After installation, launch from Spotlight (Cmd+Space → "MarkdownOpener") or the Applications folder.

## Usage

### Opening Files

- **Menu**: File → Open (Cmd+O)
- **Finder**: Double-click any `.md` file (after setting as default app)
- **Drag & Drop**: Drag markdown files onto the app icon

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+O | Open file |
| Cmd+S | Save file |
| Cmd+E | Toggle Read/Edit mode |
| Cmd+T | Toggle Table of Contents |
| Cmd+F | Search |
| Cmd++ | Increase font size |
| Cmd+- | Decrease font size |
| Escape | Close search |

### Themes

Access themes from the toolbar or View menu:
- **Light** - Clean white background
- **Dark** - Easy on the eyes in low light
- **Sepia** - Warm tones to reduce eye strain

### Typography

Customize your reading experience:
- **Font Size**: 12pt to 24pt
- **Line Height**: Compact, Normal, Relaxed, Spacious
- **Content Width**: Narrow (560px), Medium (720px), Wide (900px), Full (1100px)

## Architecture

Built with Swift and SwiftUI, using:
- **NSTextView** (AppKit) for high-performance text editing
- **WKWebView** (WebKit) for rendered markdown preview
- **swift-markdown** for CommonMark-compliant parsing

## License

MIT License
