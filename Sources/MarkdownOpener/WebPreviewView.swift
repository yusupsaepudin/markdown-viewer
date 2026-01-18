import SwiftUI
import WebKit

struct WebPreviewView: NSViewRepresentable {
    let markdown: String
    let theme: AppTheme
    let fontSize: CGFloat
    let contentWidth: CGFloat

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = MarkdownRenderer.render(
            markdown,
            theme: theme,
            fontSize: fontSize,
            contentWidth: contentWidth
        )
        webView.loadHTMLString(html, baseURL: nil)
    }
}
