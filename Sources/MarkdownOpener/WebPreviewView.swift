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

        // Check if we need to scroll to a heading
        if let headingId = scrollToId {
            // If content changed, reload and then scroll
            webView.loadHTMLString(html, baseURL: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let js = "document.getElementById('\(headingId)')?.scrollIntoView({behavior: 'smooth', block: 'start'});"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        } else {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var webView: WKWebView?
    }
}
