import WebKit

// Handles interaction with the Page Content Service JavaScript interface
// Passes setup parameters to the webpage (theme, margins, etc) and sets up a listener to recieve events (link tapped, image tapped, etc) through the messaging bridge
// https://www.mediawiki.org/wiki/Page_Content_Service
final class PageContentServiceSetupScript: WKUserScript   {
    struct Parameters: Codable {
        struct Margins: Codable {
            // these values are strings to allow for units to be included
            let top: String
            let right: String
            let bottom: String
            let left: String
        }
        let theme: String
        let leadImageHeight: String // units are included
        let margins: Margins
    }
    
    static let paramsEncoder = JSONEncoder()
    required init(_ parameters: Parameters, messageHandlerName: String) throws {
        let setupParamsJSONData = try PageContentServiceSetupScript.paramsEncoder.encode(parameters)
        let setupParamsJSONString = String(data: setupParamsJSONData, encoding: .utf8) ?? ""
        let source = """
        document.pcsActionHandler = (action) => {
          window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
        };
        document.pcsSetupSettings = JSON.parse('\(setupParamsJSONString)');
        """
        super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
}
