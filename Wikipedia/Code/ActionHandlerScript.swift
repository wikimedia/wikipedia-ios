import WebKit



// Handles interaction with the Page Content Service JavaScript interface
// Passes setup parameters to the webpage (theme, margins, etc) and sets up a listener to recieve events (link tapped, image tapped, etc) through the messaging bridge
// https://www.mediawiki.org/wiki/Page_Content_Service
final class PageContentService   {
    struct Parameters: Codable {
        let platform = "ios"
        static let clientVersion = Bundle.main.wmf_shortVersionString() // static to only pull this once
        let clientVersion = Parameters.clientVersion
        
        struct L10n: Codable {
            let addTitleDescription: String
            let tableInfobox: String
            let tableOther: String
            let tableClose: String
        }
        let l10n: L10n
        
        let theme: String
        let dimImages: Bool

        struct Margins: Codable {
            // these values are strings to allow for units to be included
            let top: String
            let right: String
            let bottom: String
            let left: String
        }
        let margins: Margins
        let leadImageHeight: String // units are included

        let areTablesInitiallyExpanded: Bool
        let textSizeAdjustmentPercentage: String // string like '125%'
        
        let userGroups: [String]
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
    
    final class PropertiesScript: WKUserScript {
        required init(messageHandlerName: String) {
               let source = """
               const leadImage = pcs.c1.Page.getLeadImage();
               const properties = { leadImage };
               window.webkit.messageHandlers.\(messageHandlerName).postMessage({action: 'properties', data: properties});
               """
               super.init(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
}
