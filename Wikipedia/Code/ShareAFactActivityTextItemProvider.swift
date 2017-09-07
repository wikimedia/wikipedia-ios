import UIKit

class ShareAFactActivityTextItemProvider: UIActivityItemProvider {
    let text: String
    let articleTitle: String
    let articleURL: URL
    
    required init(text: String, articleTitle: String, articleURL: URL) {
        self.text = text
        self.articleTitle = articleTitle
        self.articleURL = articleURL
        super.init(placeholderItem: defaultRepresentation)
    }
    
    override var item: Any {
        let type = activityType ?? .message
        switch type {
        case .message:
            return messageRepresentation
        case .postToFacebook:
            fallthrough
        case .postToTwitter:
            return socialRepresentation
        default:
             return defaultRepresentation
        }
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return articleTitle
    }
    
    var defaultRepresentation: String {
        let format = WMFLocalizedString("share-default-format", value: "“%1$@”\n\nfrom “%2$@”\n\n%3$@", comment: "Share string format for email and copied text. %1$@ is replaced with the selected text, %2$@ is replaced with the article title, %3$@ is replaced with the articleURL.")
        return String.localizedStringWithFormat(format, text, articleTitle, articleURL.absoluteString)
    }
    
    var messageRepresentation: String {
        let format = WMFLocalizedString("share-message-format", value: "“%1$@” %2$@", comment: "Share string format for messages. %1$@ is replaced with the article title, %2$@ is replaced with the article URL.")
        return String.localizedStringWithFormat(format, articleTitle, articleURL.absoluteString)
    }
    
    var socialRepresentation: String {
        let format = WMFLocalizedString("share-social-format", value: "“%1$@” via @Wikipedia, %2$@", comment: "Share string format for social platforms. %1$@ is replaced with the article title, %2$@ is replaced with the article URL.")
        return String.localizedStringWithFormat(format, articleTitle, articleURL.absoluteString)
    }

}
