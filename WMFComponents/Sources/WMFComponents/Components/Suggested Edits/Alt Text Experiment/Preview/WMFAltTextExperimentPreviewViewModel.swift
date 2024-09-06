import UIKit
import WMFData

public struct WMFAltTextExperimentPreviewViewModel {
    public let image: UIImage 
    public let altText: String
    public let caption: String?
    public let localizedStrings: LocalizedStrings
    public let articleURL: URL
    public let fullArticleWikitextWithImage: String
    public let originalImageWikitext: String
    public let isFlowB: Bool
    public let sectionID: Int?
    public let lastRevisionID: UInt64
    public let localizedEditSummary: String
    public let filename: String
    public let project: WMFProject

    public struct LocalizedStrings {
        public let altTextTitle: String
        public let captionTitle: String
        public let title: String
        public let footerText: String
        public let publishTitle: String

        public init(altTextTitle: String, captionTitle: String, title: String, footerText: String, publishTitle: String) {
            self.altTextTitle = altTextTitle
            self.captionTitle = captionTitle
            self.title = title
            self.footerText = footerText
            self.publishTitle = publishTitle
        }
    }

    public init(image: UIImage, altText: String, caption: String?, localizedStrings: LocalizedStrings, articleURL: URL, fullArticleWikitextWithImage: String, originalImageWikitext: String, isFlowB: Bool, sectionID: Int?, lastRevisionID: UInt64, localizedEditSummary: String, filename: String, project: WMFProject) {
        self.image = image
        self.altText = altText
        self.caption = caption
        self.localizedStrings = localizedStrings
        self.articleURL = articleURL
        self.fullArticleWikitextWithImage = fullArticleWikitextWithImage
        self.originalImageWikitext = originalImageWikitext
        self.isFlowB = isFlowB
        self.sectionID = sectionID
        self.lastRevisionID = lastRevisionID
        self.localizedEditSummary = localizedEditSummary
        self.filename = filename
        self.project = project
    }

}
