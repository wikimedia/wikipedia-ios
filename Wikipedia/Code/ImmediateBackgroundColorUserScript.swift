import Foundation

// sets the background color of the body .atDocumentStart to eliminate color flash on load
class ImmediateBackgroundColorUserScript: WKUserScript {
    init(_ colorHexString: String) {
        let source = """
        var css = 'body, .CodeMirror { background: #\(colorHexString); }';
        var style = document.createElement('style');
        style.type = 'text/css';
        style.innerText = css;
        document.head.appendChild(style);
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
