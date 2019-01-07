import Foundation

// sets the theme using wmf.applyTheme atDocumentEnd
class ThemeUserScript: WKUserScript {
    init(_ theme: Theme) {
        let source = """
        wmf.applyTheme('\(theme.webName)');
        """
        super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}
