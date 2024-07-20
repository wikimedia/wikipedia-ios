import WebKit
import CocoaLumberjackSwift

extension WKWebView {
    private func selectedTextEditInfo(from dictionary: [String: Any]) -> SelectedTextEditInfo? {
        guard
            let selectedAndAdjacentTextDict = dictionary["selectedAndAdjacentText"] as? [String: Any],
            let selectedText = selectedAndAdjacentTextDict["selectedText"] as? String,
            let textBeforeSelectedText = selectedAndAdjacentTextDict["textBeforeSelectedText"] as? String,
            let textAfterSelectedText = selectedAndAdjacentTextDict["textAfterSelectedText"] as? String,
            let isSelectedTextInTitleDescription = dictionary["isSelectedTextInTitleDescription"] as? Bool,
            let sectionID = dictionary["sectionID"] as? Int
            else {
                DDLogWarn("Error converting dictionary to SelectedTextEditInfo")
                return nil
        }
        let descriptionSource: ArticleDescriptionSource?
        if let descriptionSourceString = dictionary["descriptionSource"] as? String {
            descriptionSource = ArticleDescriptionSource(rawValue: descriptionSourceString)
        } else {
            descriptionSource = nil
        }
        let selectedAndAdjacentText = SelectedAndAdjacentText(selectedText: selectedText, textAfterSelectedText: textAfterSelectedText, textBeforeSelectedText: textBeforeSelectedText)
        return SelectedTextEditInfo(selectedAndAdjacentText: selectedAndAdjacentText, isSelectedTextInTitleDescription: isSelectedTextInTitleDescription, sectionID: sectionID, descriptionSource: descriptionSource)
    }
    
    @objc func wmf_getSelectedTextEditInfo(completionHandler: ((SelectedTextEditInfo?, Error?) -> Void)? = nil) {
        evaluateJavaScript("window.wmf.editTextSelection.getSelectedTextEditInfo()") { [weak self] (result, error) in
            guard let error = error else {
                guard let completionHandler = completionHandler else {
                    return
                }
                guard
                    let resultDict = result as? [String: Any],
                    let selectedTextEditInfo = self?.selectedTextEditInfo(from: resultDict)
                else {
                    DDLogWarn("Error handling 'getSelectedTextEditInfo()' dictionary response")
                    return
                }
                
                completionHandler(selectedTextEditInfo, nil)
                return
            }
            DDLogWarn("Error when evaluating javascript on fetch and transform: \(error)")
        }
    }
}

class SelectedAndAdjacentText {
    public let selectedText: String
    public let textAfterSelectedText: String
    public let textBeforeSelectedText: String
    init(selectedText: String, textAfterSelectedText: String, textBeforeSelectedText: String) {
        self.selectedText = selectedText
        self.textAfterSelectedText = textAfterSelectedText
        self.textBeforeSelectedText = textBeforeSelectedText
    }
}

@objcMembers class SelectedTextEditInfo: NSObject {
    public let selectedAndAdjacentText: SelectedAndAdjacentText
    public let isSelectedTextInTitleDescription: Bool
    public let sectionID: Int
    public let descriptionSource: ArticleDescriptionSource?
    init(selectedAndAdjacentText: SelectedAndAdjacentText, isSelectedTextInTitleDescription: Bool, sectionID: Int, descriptionSource: ArticleDescriptionSource?) {
        self.selectedAndAdjacentText = selectedAndAdjacentText
        self.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
        self.sectionID = sectionID
        self.descriptionSource = descriptionSource
    }
}
