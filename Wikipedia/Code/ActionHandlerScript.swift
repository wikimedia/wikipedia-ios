import WebKit

/// Handles interaction with the Page Content Service JavaScript interface
/// Passes setup parameters to the webpage (theme, margins, etc) and sets up a listener to recieve events (link tapped, image tapped, etc) through the messaging bridge
/// https://www.mediawiki.org/wiki/Page_Content_Service
final class PageContentService {
    struct Setup {
        struct Parameters: Codable {
            var platform = "ios"
            var version = 1
            
            var theme: String
            var dimImages: Bool

            struct Margins: Codable {
                // these values are strings to allow for units to be included
                let top: String
                let right: String
                let bottom: String
                let left: String
            }
            var margins: Margins
            var leadImageHeight: String // units are included

            var areTablesInitiallyExpanded: Bool
            var textSizeAdjustmentPercentage: String // string like '125%'
            
            var userGroups: [String]
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
            let title: String
            let menu: Menu
            let readMore: ReadMore
        }
    }
    
    static let paramsEncoder = JSONEncoder()
    static let messageHandlerName = "pcs"
    
    /// - Parameter encodable: the object to encode
    /// - Returns: a JavaScript string that will call JSON.parse on the JSON representation of the encodable
    static func getJavascriptFor<T>(_ encodable: T) throws -> String where T: Encodable {
        let data = try PageContentService.paramsEncoder.encode(encodable)
        guard let string = String(data: data, encoding: .utf8) else {
            throw RequestError.invalidParameters
        }
        return "JSON.parse(`\(string.sanitizedForJavaScriptTemplateLiterals)`)"
    }
    
    final class SetupScript: PageUserScript {
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
    
    final class PropertiesScript: PageUserScript {
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
        init() {
            super.init(source: PropertiesScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
    
    final class UtilitiesScript: PageUserScript {
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
        
        init() {
            super.init(source: UtilitiesScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
    
    
    final class StyleScript: PageUserScript {
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
        
        init() {
            super.init(source: StyleScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }

    final class SignificantEventsStyleScript: PageUserScript {
        
        static func sourceForTheme(_ theme: String) -> String {
            
            let cssFileName: String
            switch theme {
            case "sepia": cssFileName = "significant-events-styles-sepia"
            case "dark": cssFileName = "significant-events-styles-dark"
            case "black": cssFileName = "significant-events-styles-black"
            default: cssFileName = "significant-events-styles-light"
            }
            
            guard
                let originalFileURL = Bundle.wmf.url(forResource: "styleoverrides", withExtension: "css", subdirectory: "assets"),
                let originalData = try? Data(contentsOf: originalFileURL),
                let originalCssString = String(data: originalData, encoding: .utf8)?.sanitizedForJavaScriptTemplateLiterals,
                let baseFileURL = Bundle.wmf.url(forResource: "significant-events-styles-base", withExtension: "css", subdirectory: "assets"),
                let baseData = try? Data(contentsOf: baseFileURL),
                let baseCssString = String(data: baseData, encoding: .utf8)?.sanitizedForJavaScriptTemplateLiterals,
                let fileURL = Bundle.wmf.url(forResource: cssFileName, withExtension: "css", subdirectory: "assets"),
                let data = try? Data(contentsOf: fileURL),
                let cssString = String(data: data, encoding: .utf8)?.sanitizedForJavaScriptTemplateLiterals
            else {
                return ""
            }
            return """
                    var existing = document.getElementById('significant-events-styles');
                    if (existing) {
                        existing.remove();
                    }
                    var style = document.createElement('style');
                    style.id = 'significant-events-styles';
                    style.innerHTML = `\(originalCssString + baseCssString + cssString)`;
                    document.head.appendChild(style);
                """
        }
        
        init(theme: String) {
            
            let calculatedSource = SignificantEventsStyleScript.sourceForTheme(theme)
            
            super.init(source: calculatedSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
}
