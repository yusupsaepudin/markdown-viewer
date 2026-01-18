import SwiftUI
import WebKit

struct WebPreviewView: NSViewRepresentable {
    let markdown: String
    let theme: AppTheme
    let fontSize: CGFloat
    let contentWidth: CGFloat
    let lineHeight: LineHeight
    let scrollToId: String?

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = MarkdownRenderer.render(
            markdown,
            theme: theme,
            fontSize: fontSize,
            contentWidth: contentWidth,
            lineHeight: lineHeight.value
        )

        // Check if we need to scroll to a heading (without reload)
        if let headingId = scrollToId, !headingId.isEmpty {
            // Only use JavaScript scroll - don't reload
            let js = """
            (function() {
                var el = document.getElementById('\(headingId)');
                if (el) {
                    el.scrollIntoView({behavior: 'smooth', block: 'start'});
                }
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
            return
        }

        // Only reload HTML if content actually changed
        let newContentHash = html.hashValue
        if context.coordinator.lastContentHash != newContentHash {
            context.coordinator.lastContentHash = newContentHash
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var webView: WKWebView?
        var lastContentHash: Int = 0
    }
}
