import WebKit

/// Handles interaction with the Page Content Service JavaScript interface
/// Passes setup parameters to the webpage (theme, margins, etc) and sets up a listener to recieve events (link tapped, image tapped, etc) through the messaging bridge
/// https://www.mediawiki.org/wiki/Page_Content_Service
final class PageContentService   {
    struct Setup {
        struct Parameters: Codable {
            static let platform = "ios"
            static let clientVersion = Bundle.main.wmf_shortVersionString() // static to only pull this once
        
            let platform = Parameters.platform
            let clientVersion = Parameters.clientVersion
            
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
    }
    
    struct Footer {
        struct Menu: Codable {
            static let fragment = "pcs-footer-container-menu"
            enum Item: String, Codable {
                case lastEdited
                case pageIssues
                case disambiguation
                case coordinate
                case talkPage
            }
            let items: [Item]
            let editedDaysAgo: Int?
        }
        
        struct ReadMore: Codable {
            static let fragment = "pcs-footer-container-readmore"
            let itemCount: Int
            let baseURL: String
        }
        
        struct Parameters: Codable {
            let platform = Setup.Parameters.platform
            let clientVersion = Setup.Parameters.clientVersion
            let title: String
            let menu: Menu
            let readMore: ReadMore
        }
    }
    
    static let paramsEncoder = JSONEncoder()
    static let messageHandlerName = "pcs"
    
    /// - Parameter encodable: the object to encode
    /// - Returns: a JavaScript string that will call JSON.parse on the JSON representation of the encodable
    class func getJavascriptFor<T>(_ encodable: T) throws -> String where T: Encodable {
        let data = try PageContentService.paramsEncoder.encode(encodable)
        guard let string = String(data: data, encoding: .utf8) else {
            throw RequestError.invalidParameters
        }
        return "JSON.parse('\(string)')"
    }
    
    final class SetupScript: WKUserScript {
        required init(_ parameters: Setup.Parameters) throws {

               let source = """
               document.pcsActionHandler = (action) => {
                window.webkit.messageHandlers.\(PageContentService.messageHandlerName).postMessage(action)
               };
               document.pcsSetupSettings = \(try PageContentService.getJavascriptFor(parameters));
               """
               super.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        }
    }
    
    final class PropertiesScript: WKUserScript {
        static let source: String = {
            guard
                let fileURL = Bundle.main.url(forResource: "Properties", withExtension: "js"),
                let data = try? Data(contentsOf: fileURL),
                let jsString = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "{{messageHandlerName}}", with: PageContentService.messageHandlerName)
            else {
                return ""
            }
            return jsString
        }()
        required override init() {
            super.init(source: PropertiesScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
    
    final class UtilitiesScript: WKUserScript {
        static let source: String = {
            guard
                let fileURL = Bundle.wmf.url(forResource: "index", withExtension: "js", subdirectory: "assets"),
                let data = try? Data(contentsOf: fileURL),
                let jsString = String(data: data, encoding: .utf8)
            else {
                return ""
            }
            return jsString
        }()
        
        required override init() {
            super.init(source: UtilitiesScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
    
    
    final class StyleScript: WKUserScript {
        static let source: String = {
            guard
                let fileURL = Bundle.wmf.url(forResource: "styleoverrides", withExtension: "css", subdirectory: "assets"),
                let data = try? Data(contentsOf: fileURL),
                let cssString = String(data: data, encoding: .utf8)?.sanitizedForJavaScriptTemplateLiterals
            else {
                return ""
            }
            return "const style = document.createElement('style'); style.innerHTML = `\(cssString)`; document.head.appendChild(style);"
        }()
        
        required override init() {
            super.init(source: StyleScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
}
