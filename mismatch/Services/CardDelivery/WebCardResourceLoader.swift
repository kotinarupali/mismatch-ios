import Foundation

enum WebCardResourceLoader {
    private static var cachedIndexHTML: String?
    private static var cachedCSS: String?
    private static var cachedJS: String?

    static func indexHTML(replacingToken token: String) -> String {
        let template = loadIndexHTML()
        return template.replacingOccurrences(of: "{{TOKEN}}", with: token)
    }

    static func css() -> String {
        if let cachedCSS { return cachedCSS }
        let content = loadResource(name: "card", ext: "css") ?? fallbackCSS
        cachedCSS = content
        return content
    }

    static func js() -> String {
        if let cachedJS { return cachedJS }
        let content = loadResource(name: "card", ext: "js") ?? fallbackJS
        cachedJS = content
        return content
    }

    static func validateBundleResources() -> Bool {
        !loadIndexHTML().isEmpty && !js().isEmpty
    }

    private static func loadIndexHTML() -> String {
        if let cachedIndexHTML { return cachedIndexHTML }
        let content = loadResource(name: "index", ext: "html") ?? fallbackIndexHTML
        cachedIndexHTML = content
        return content
    }

    private static func loadResource(name: String, ext: String) -> String? {
        let candidates = [
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/WebCard"),
            Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "WebCard"),
            Bundle.main.url(forResource: name, withExtension: ext)
        ]

        for url in candidates.compactMap({ $0 }) {
            if let content = try? String(contentsOf: url, encoding: .utf8), !content.isEmpty {
                return content
            }
        }
        return nil
    }

    private static let fallbackIndexHTML = """
    <!DOCTYPE html>
    <html lang="en"><head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mismatch</title>
    <style>body{font-family:-apple-system,sans-serif;margin:0;padding:24px;background:#111;color:#fff;min-height:100vh}main{max-width:420px;margin:0 auto}.loading{opacity:.85;text-align:center}</style>
    <link rel="stylesheet" href="/card.css">
    </head><body>
    <main id="app"><p class="loading">Loading game…</p></main>
    <script>window.SESSION_TOKEN="{{TOKEN}}";</script>
    <script src="/card.js" defer></script>
    </body></html>
    """

    private static let fallbackCSS = "body{font-family:sans-serif;background:#111;color:#fff;padding:24px}"

    private static let fallbackJS = """
    document.getElementById('app').innerHTML='<p>Web assets failed to load. Reinstall the app or use pass-the-phone.</p>';
    """
}
