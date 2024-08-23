import Foundation
import WMFData

public struct WMFAltTextExperimentViewModel {
    
    public struct LocalizedStrings {
        public let articleNavigationBarTitle: String
        public let editSummary: String
        
        public init(articleNavigationBarTitle: String, editSummary: String) {
            self.articleNavigationBarTitle = articleNavigationBarTitle
            self.editSummary = editSummary
        }
    }
    
    public let localizedStrings: LocalizedStrings
    public let firstTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings
    public let secondTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings
    public let thirdTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings
    public let articleTitle: String
    public let caption: String?
    public let imageFullURLString: String?
    public let imageThumbURLString: String?
    public let filename: String
    public let imageWikitext: String
    public let fullArticleWikitextWithImage: String
    public let lastRevisionID: UInt64
    public let sectionID: Int?
    public let isFlowB: Bool
    public let project: WMFProject
    public let learnMoreURL = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Add_Alt_Text")

    public init(localizedStrings: LocalizedStrings, firstTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings, secondTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings, thirdTooltipLocalizedStrings: WMFTooltipViewModel.LocalizedStrings, articleTitle: String, caption: String?, imageFullURLString: String?, imageThumbURLString: String?, filename: String, imageWikitext: String, fullArticleWikitextWithImage: String, lastRevisionID: UInt64, sectionID: Int?, isFlowB: Bool, project: WMFProject) {
        self.localizedStrings = localizedStrings
        self.firstTooltipLocalizedStrings = firstTooltipLocalizedStrings
        self.secondTooltipLocalizedStrings = secondTooltipLocalizedStrings
        self.thirdTooltipLocalizedStrings = thirdTooltipLocalizedStrings
        self.articleTitle = articleTitle
        self.caption = caption
        self.imageFullURLString = imageFullURLString
        self.imageThumbURLString = imageThumbURLString
        self.filename = filename
        self.imageWikitext = imageWikitext
        self.fullArticleWikitextWithImage = fullArticleWikitextWithImage
        self.lastRevisionID = lastRevisionID
        self.sectionID = sectionID
        self.isFlowB = isFlowB
        self.project = project
    }
    
    var imageFullURL: URL? {
        guard let imageFullURLString else { return nil }
        return URL(string: "https:\(imageFullURLString)")
    }
}

