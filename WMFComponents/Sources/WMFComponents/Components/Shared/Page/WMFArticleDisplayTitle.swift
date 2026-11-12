import Foundation
import WMFData

enum WMFArticleDisplayTitle {

    /// On wikis with language variants, the summary's display title is in the user's variant (蘭香如故), unlike the stored title (兰香如故)
    static func displayTitle(title: String, summaryDisplayTitle: String?, project: WMFProject) -> String {
        guard project.languageVariantCode != nil,
              let summaryDisplayTitle = summaryDisplayTitle?.removingHTML.trimmingCharacters(in: .whitespacesAndNewlines),
              !summaryDisplayTitle.isEmpty else {
            return title
        }
        return summaryDisplayTitle
    }
}
