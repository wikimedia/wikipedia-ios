
@objc public enum WMFWKScriptMessage: Int {
    case unknown
    case consoleMessage
    case clickLink
    case clickImage
    case clickReference
    case clickEdit
    case nonAnchorTouchEndedWithoutDragging
    case lateJavascriptTransform
    case articleState
    case findInPageMatchesFound
    case footerReadMoreSaveClicked
    case footerReadMoreTitlesShown
    case footerMenuItemClicked
    case footerLegalLicenseLinkClicked
}

extension WKScriptMessage {

    public class func wmf_typeForMessageName(_ name: String) -> WMFWKScriptMessage {
        switch name {
        case "nonAnchorTouchEndedWithoutDragging":
            return .nonAnchorTouchEndedWithoutDragging
        case "linkClicked":
            return .clickLink
        case "imageClicked":
            return .clickImage
        case "referenceClicked":
            return .clickReference
        case "editClicked":
            return .clickEdit
        case "lateJavascriptTransform":
            return .lateJavascriptTransform
        case "articleState":
            return .articleState
        case "sendJavascriptConsoleLogMessageToXcodeConsole":
            return .consoleMessage
        case "findInPageMatchesFound":
            return .findInPageMatchesFound
        case "footerReadMoreSaveClicked":
            return .footerReadMoreSaveClicked
        case "footerReadMoreTitlesShown":
            return .footerReadMoreTitlesShown
        case "footerMenuItemClicked":
            return .footerMenuItemClicked
        case "footerLegalLicenseLinkClicked":
            return .footerLegalLicenseLinkClicked
        default:
            return .unknown
        }
    }

    public func wmf_safeMessageBodyForType(_ type: WMFWKScriptMessage) -> Any? {
        switch type {
        case .nonAnchorTouchEndedWithoutDragging,
             .clickLink,
             .clickImage,
             .clickReference,
             .clickEdit,
             .consoleMessage,
             .footerReadMoreSaveClicked:
            if body is Dictionary<String, Any>{
                return (body as! NSDictionary).wmf_dictionaryByRemovingNullObjects()
            }
        case .lateJavascriptTransform,
             .articleState,
             .footerMenuItemClicked,
             .footerLegalLicenseLinkClicked:
            if body is String {
                return body
            }
        case .findInPageMatchesFound,
             .footerReadMoreTitlesShown:
            if body is Array<Any>{
                return body
            }
        case .unknown:
            if body is NSNull{
                return body
            }
        }
        assert(false, "Unexpected script message body kind of class!")
        return nil
    }
}
