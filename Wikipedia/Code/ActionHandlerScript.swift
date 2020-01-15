import WebKit



// Handles interaction with the Page Content Service JavaScript interface
// Passes setup parameters to the webpage (theme, margins, etc) and sets up a listener to recieve events (link tapped, image tapped, etc) through the messaging bridge
// https://www.mediawiki.org/wiki/Page_Content_Service
final class PageContentService   {
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
    
    class func getJavascriptFor<T>(_ encodable: T) throws -> String where T: Encodable {
        let data = try PageContentService.paramsEncoder.encode(encodable)
        guard let string = String(data: data, encoding: .utf8) else {
            throw RequestError.invalidParameters
        }
        return "JSON.parse('\(string)')"
    }
    
    final class SetupScript: WKUserScript {
        required init(_ parameters: Parameters, messageHandlerName: String) throws {

               let source = """
               document.pcsActionHandler = (action) => {
                 window.webkit.messageHandlers.\(messageHandlerName).postMessage(action)
               };
               document.pcsSetupSettings = \(try PageContentService.getJavascriptFor(parameters));
               """
               super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        }
    }
}
