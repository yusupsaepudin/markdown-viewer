import SwiftUI
import WebKit

struct WebPreviewView: NSViewRepresentable {
    let markdown: String
    let theme: AppTheme
    let fontSize: CGFloat
    let contentWidth: CGFloat
    let lineHeight: LineHeight
    let scrollToId: String?
    let searchText: String
    let onActiveHeadingChange: (String?) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Add script message handler for scroll spy
        let contentController = config.userContentController
        contentController.add(context.coordinator, name: "scrollSpy")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.onActiveHeadingChange = onActiveHeadingChange
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onActiveHeadingChange = onActiveHeadingChange

        let html = MarkdownRenderer.render(
            markdown,
            theme: theme,
            fontSize: fontSize,
            contentWidth: contentWidth,
            lineHeight: lineHeight.value
        )

        // Check if we need to scroll to a heading (without reload)
        if let headingId = scrollToId, !headingId.isEmpty {
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

        // Handle search
        if !searchText.isEmpty {
            let escapedSearch = searchText
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
                .replacingOccurrences(of: "\n", with: "\\n")

            let searchJS = """
            (function() {
                window.find('\(escapedSearch)', false, false, true, false, true, false);
            })();
            """
            webView.evaluateJavaScript(searchJS, completionHandler: nil)
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

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var webView: WKWebView?
        var lastContentHash: Int = 0
        var onActiveHeadingChange: ((String?) -> Void)?

        // Handle messages from JavaScript (scroll spy)
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "scrollSpy", let headingId = message.body as? String {
                DispatchQueue.main.async {
                    self.onActiveHeadingChange?(headingId.isEmpty ? nil : headingId)
                }
            }
        }

        // Intercept link clicks to open in browser
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Allow initial load and internal navigation
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }

            // Open external links in default browser
            if let url = navigationAction.request.url {
                if url.scheme == "http" || url.scheme == "https" {
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }

        // Inject scroll spy script after page loads
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let scrollSpyJS = """
            (function() {
                let ticking = false;

                function updateActiveHeading() {
                    const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
                    let activeId = '';
                    const scrollTop = window.scrollY || document.documentElement.scrollTop;
                    const offset = 100;

                    for (let i = headings.length - 1; i >= 0; i--) {
                        const heading = headings[i];
                        const rect = heading.getBoundingClientRect();
                        if (rect.top <= offset) {
                            activeId = heading.id || '';
                            break;
                        }
                    }

                    // If at the very top, use first heading
                    if (scrollTop < 50 && headings.length > 0) {
                        activeId = headings[0].id || '';
                    }

                    window.webkit.messageHandlers.scrollSpy.postMessage(activeId);
                }

                window.addEventListener('scroll', function() {
                    if (!ticking) {
                        window.requestAnimationFrame(function() {
                            updateActiveHeading();
                            ticking = false;
                        });
                        ticking = true;
                    }
                });

                // Initial check
                setTimeout(updateActiveHeading, 100);
            })();
            """
            webView.evaluateJavaScript(scrollSpyJS, completionHandler: nil)
        }
    }
}
