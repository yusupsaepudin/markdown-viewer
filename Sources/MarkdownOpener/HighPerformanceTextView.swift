import SwiftUI
import AppKit

/// High-performance text view using NSTextView instead of SwiftUI's TextEditor
/// Optimized for large markdown files (1000+ lines)
struct HighPerformanceTextView: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let lineSpacing: CGFloat
    let backgroundColor: NSColor
    let textColor: NSColor

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        // Performance optimizations
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false

        // Layout settings
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0

        // Appearance
        textView.drawsBackground = true
        textView.backgroundColor = backgroundColor
        textView.insertionPointColor = textColor

        // Set initial text and styling
        textView.font = font
        textView.textColor = textColor
        textView.string = text

        // Set line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        // Apply to existing text
        if !text.isEmpty {
            textView.textStorage?.addAttributes([
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: text.count))
        }

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update if text changed from outside (not from typing)
        if textView.string != text && !context.coordinator.isUpdating {
            context.coordinator.isUpdating = true

            // Preserve cursor position
            let selectedRanges = textView.selectedRanges

            textView.string = text

            // Restore styling
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing

            if !text.isEmpty {
                textView.textStorage?.addAttributes([
                    .font: font,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle
                ], range: NSRange(location: 0, length: text.count))
            }

            // Restore cursor if valid
            let validRanges = selectedRanges.compactMap { range -> NSValue? in
                let r = range.rangeValue
                if r.location <= text.count {
                    let newLength = min(r.length, text.count - r.location)
                    return NSValue(range: NSRange(location: r.location, length: newLength))
                }
                return nil
            }
            if !validRanges.isEmpty {
                textView.selectedRanges = validRanges
            }

            context.coordinator.isUpdating = false
        }

        // Update appearance if changed
        textView.backgroundColor = backgroundColor
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.font = font
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighPerformanceTextView
        var textView: NSTextView?
        var isUpdating = false
        private var debounceTimer: DispatchWorkItem?

        init(_ parent: HighPerformanceTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }

            // Debounce text updates to parent (50ms)
            debounceTimer?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.isUpdating = true
                self.parent.text = textView.string
                self.isUpdating = false
            }
            debounceTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
        }
    }
}

// MARK: - Theme-aware wrapper
struct PerformantTextEditor: View {
    @Binding var text: String
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let theme: AppTheme

    private var font: NSFont {
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    private var lineSpacing: CGFloat {
        (lineHeight - 1) * fontSize
    }

    private var backgroundColor: NSColor {
        switch theme {
        case .light: return NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        case .dark: return NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        case .sepia: return NSColor(red: 0.97, green: 0.94, blue: 0.88, alpha: 1)
        }
    }

    private var textColor: NSColor {
        switch theme {
        case .light: return NSColor(red: 0.14, green: 0.16, blue: 0.19, alpha: 1)
        case .dark: return NSColor(red: 0.90, green: 0.93, blue: 0.95, alpha: 1)
        case .sepia: return NSColor(red: 0.36, green: 0.29, blue: 0.22, alpha: 1)
        }
    }

    var body: some View {
        HighPerformanceTextView(
            text: $text,
            font: font,
            lineSpacing: lineSpacing,
            backgroundColor: backgroundColor,
            textColor: textColor
        )
    }
}
