import Foundation
import Markdown

struct MarkdownRenderer {
    static func render(
        _ markdown: String,
        theme: AppTheme,
        fontSize: CGFloat,
        contentWidth: CGFloat
    ) -> String {
        let document = Document(parsing: markdown)
        var htmlVisitor = HTMLVisitor()
        let bodyHTML = htmlVisitor.visit(document)

        let themeCSS = getThemeCSS(theme)
        let highlightTheme = getHighlightTheme(theme)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/\(highlightTheme).min.css">
            <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
            <style>
                * {
                    box-sizing: border-box;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: \(Int(fontSize))px;
                    line-height: 1.7;
                    padding: 32px 24px;
                    max-width: \(Int(contentWidth))px;
                    margin: 0 auto;
                    \(themeCSS.body)
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                    font-weight: 600;
                    line-height: 1.3;
                    \(themeCSS.heading)
                }
                h1 {
                    font-size: 2em;
                    padding-bottom: 0.3em;
                    border-bottom: 1px solid;
                    \(themeCSS.h1Border)
                }
                h2 {
                    font-size: 1.5em;
                    padding-bottom: 0.3em;
                    border-bottom: 1px solid;
                    \(themeCSS.h2Border)
                }
                h3 { font-size: 1.25em; }
                h4 { font-size: 1em; }
                p {
                    margin-bottom: 1em;
                    \(themeCSS.text)
                }
                a {
                    text-decoration: none;
                    \(themeCSS.link)
                }
                a:hover {
                    text-decoration: underline;
                }
                code:not(pre code) {
                    padding: 0.2em 0.4em;
                    border-radius: 4px;
                    font-size: 90%;
                    font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;
                    \(themeCSS.inlineCode)
                }
                pre {
                    padding: 16px;
                    overflow: auto;
                    border-radius: 8px;
                    font-size: 90%;
                    line-height: 1.5;
                    margin: 1em 0;
                    \(themeCSS.codeBlock)
                }
                pre code {
                    font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace;
                    background: transparent !important;
                    padding: 0;
                }
                blockquote {
                    padding: 0.5em 1em;
                    margin: 1em 0;
                    border-left: 4px solid;
                    border-radius: 0 4px 4px 0;
                    \(themeCSS.blockquote)
                }
                blockquote p {
                    margin: 0;
                }
                ul, ol {
                    padding-left: 1.5em;
                    margin-bottom: 1em;
                }
                li {
                    margin: 0.3em 0;
                    \(themeCSS.text)
                }
                table {
                    border-collapse: collapse;
                    margin: 1em 0;
                    width: 100%;
                    \(themeCSS.table)
                }
                table th, table td {
                    padding: 10px 14px;
                    border: 1px solid;
                    \(themeCSS.tableCell)
                }
                table th {
                    font-weight: 600;
                    \(themeCSS.tableHeader)
                }
                hr {
                    height: 2px;
                    border: 0;
                    margin: 2em 0;
                    \(themeCSS.hr)
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 1em 0;
                }
                strong {
                    font-weight: 600;
                }
            </style>
        </head>
        <body>
            \(bodyHTML)
            <script>hljs.highlightAll();</script>
        </body>
        </html>
        """
    }

    private static func getHighlightTheme(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "github"
        case .dark: return "github-dark"
        case .sepia: return "stackoverflow-light"
        }
    }

    private static func getThemeCSS(_ theme: AppTheme) -> ThemeCSS {
        switch theme {
        case .light:
            return ThemeCSS(
                body: "background: #ffffff; color: #24292f;",
                heading: "color: #1f2328;",
                text: "color: #24292f;",
                link: "color: #0969da;",
                inlineCode: "background: #f6f8fa; color: #24292f;",
                codeBlock: "background: #f6f8fa;",
                blockquote: "background: #f6f8fa; border-left-color: #d0d7de; color: #57606a;",
                table: "",
                tableCell: "border-color: #d0d7de;",
                tableHeader: "background: #f6f8fa;",
                h1Border: "border-color: #d0d7de;",
                h2Border: "border-color: #d0d7de;",
                hr: "background: #d0d7de;"
            )
        case .dark:
            return ThemeCSS(
                body: "background: #0d1117; color: #e6edf3;",
                heading: "color: #ffffff;",
                text: "color: #e6edf3;",
                link: "color: #58a6ff;",
                inlineCode: "background: #343942; color: #e6edf3;",
                codeBlock: "background: #161b22;",
                blockquote: "background: #161b22; border-left-color: #3b434b; color: #8b949e;",
                table: "",
                tableCell: "border-color: #30363d;",
                tableHeader: "background: #161b22;",
                h1Border: "border-color: #30363d;",
                h2Border: "border-color: #30363d;",
                hr: "background: #30363d;"
            )
        case .sepia:
            return ThemeCSS(
                body: "background: #f9f5e9; color: #5c4b37;",
                heading: "color: #3d3125;",
                text: "color: #5c4b37;",
                link: "color: #8b6914;",
                inlineCode: "background: #f0e8d6; color: #5c4b37;",
                codeBlock: "background: #f0e8d6;",
                blockquote: "background: #f0e8d6; border-left-color: #d4c4a8; color: #7a6b57;",
                table: "",
                tableCell: "border-color: #d4c4a8;",
                tableHeader: "background: #f0e8d6;",
                h1Border: "border-color: #d4c4a8;",
                h2Border: "border-color: #d4c4a8;",
                hr: "background: #d4c4a8;"
            )
        }
    }
}

private struct ThemeCSS {
    let body: String
    let heading: String
    let text: String
    let link: String
    let inlineCode: String
    let codeBlock: String
    let blockquote: String
    let table: String
    let tableCell: String
    let tableHeader: String
    let h1Border: String
    let h2Border: String
    let hr: String
}

struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }

    mutating func visitDocument(_ document: Document) -> String {
        defaultVisit(document)
    }

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.string)
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(defaultVisit(paragraph))</p>\n"
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        "<h\(heading.level)>\(defaultVisit(heading))</h\(heading.level)>\n"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(defaultVisit(strong))</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(defaultVisit(emphasis))</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language ?? ""
        let langClass = language.isEmpty ? "" : "language-\(language)"
        return "<pre><code class=\"\(langClass)\">\(escapeHTML(codeBlock.code))</code></pre>\n"
    }

    mutating func visitLink(_ link: Link) -> String {
        let href = link.destination ?? ""
        return "<a href=\"\(escapeHTML(href))\">\(defaultVisit(link))</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let src = image.source ?? ""
        let alt = image.plainText
        return "<img src=\"\(escapeHTML(src))\" alt=\"\(escapeHTML(alt))\">"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        "<ul>\n\(defaultVisit(unorderedList))</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        "<ol>\n\(defaultVisit(orderedList))</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        "<li>\(defaultVisit(listItem))</li>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(defaultVisit(blockQuote))</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitTable(_ table: Table) -> String {
        "<table>\n\(defaultVisit(table))</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        "<thead>\n<tr>\n\(defaultVisit(tableHead))</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        "<tbody>\n\(defaultVisit(tableBody))</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        "<tr>\n\(defaultVisit(tableRow))</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        let tag = tableCell.parent is Table.Head ? "th" : "td"
        return "<\(tag)>\(defaultVisit(tableCell))</\(tag)>\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(defaultVisit(strikethrough))</del>"
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
