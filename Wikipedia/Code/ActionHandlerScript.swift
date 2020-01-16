import WebKit

final class ActionHandlerScript: WKUserScript   {
    required init(theme: Theme, messageHandlerName: String) {
        let setupParams: String
        setupParams = "{theme: '\(theme.name.lowercased())', margins: {top: '16px', right: '16px', bottom: '16px', left: '16px'}, areTablesInitiallyExpanded: false}"
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = \(setupParams);
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
