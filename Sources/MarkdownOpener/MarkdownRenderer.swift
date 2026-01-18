import Foundation
import Markdown

struct MarkdownRenderer {
    static func render(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        var htmlVisitor = HTMLVisitor()
        let bodyHTML = htmlVisitor.visit(document)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css" media="(prefers-color-scheme: dark)">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css" media="(prefers-color-scheme: light)">
            <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    padding: 20px;
                    max-width: 900px;
                    margin: 0 auto;
                    background: transparent;
                }
                @media (prefers-color-scheme: dark) {
                    body { color: #e6edf3; }
                    a { color: #58a6ff; }
                    code:not(pre code) {
                        background: #343942;
                        color: #e6edf3;
                    }
                    blockquote {
                        border-left-color: #3b434b;
                        color: #8b949e;
                    }
                    table th, table td {
                        border-color: #3b434b;
                    }
                    hr {
                        background-color: #3b434b;
                    }
                }
                @media (prefers-color-scheme: light) {
                    body { color: #24292f; }
                    a { color: #0969da; }
                    code:not(pre code) {
                        background: #f6f8fa;
                        color: #24292f;
                    }
                    blockquote {
                        border-left-color: #d0d7de;
                        color: #57606a;
                    }
                    table th, table td {
                        border-color: #d0d7de;
                    }
                    hr {
                        background-color: #d0d7de;
                    }
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid; border-color: inherit; }
                h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid; border-color: inherit; }
                h3 { font-size: 1.25em; }
                p { margin-bottom: 16px; }
                code:not(pre code) {
                    padding: 0.2em 0.4em;
                    border-radius: 6px;
                    font-size: 85%;
                    font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
                }
                pre {
                    padding: 16px;
                    overflow: auto;
                    border-radius: 6px;
                    font-size: 85%;
                    line-height: 1.45;
                    margin-bottom: 16px;
                }
                pre code {
                    font-family: ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, monospace;
                    background: transparent;
                    padding: 0;
                }
                blockquote {
                    padding: 0 1em;
                    margin: 0 0 16px;
                    border-left: 0.25em solid;
                }
                ul, ol {
                    padding-left: 2em;
                    margin-bottom: 16px;
                }
                li { margin: 4px 0; }
                table {
                    border-collapse: collapse;
                    margin-bottom: 16px;
                    width: 100%;
                }
                table th, table td {
                    padding: 6px 13px;
                    border: 1px solid;
                }
                table th {
                    font-weight: 600;
                }
                hr {
                    height: 0.25em;
                    border: 0;
                    margin: 24px 0;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                a {
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
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
