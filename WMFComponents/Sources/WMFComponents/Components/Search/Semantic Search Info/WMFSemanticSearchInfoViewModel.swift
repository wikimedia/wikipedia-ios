import Foundation
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFSemanticSearchInfoViewModel: ObservableObject {

    public typealias Action = @MainActor @Sendable () -> Void

    let languageCode: String?
    let exampleQuery: String
    let exampleResult: WMFSemanticSearchResultViewModel

    private let learnMoreAction: Action
    private let closeAction: Action

    private(set) lazy var title = WMFLocalizedString("search-semantic-info-title", languageCode: languageCode, value: "What is this feature?", comment: "Title of the sheet that explains searching within articles. Opens from the info button of the semantic search entry point.")
    private(set) lazy var summary = WMFLocalizedString("search-semantic-info-summary", languageCode: languageCode, value: "Find answers to your questions inside Wikipedia articles and jump straight into the relevant passage.", comment: "First paragraph of the sheet that explains searching within articles.")
    private(set) lazy var sourcesDescription = WMFLocalizedString("search-semantic-info-sources", languageCode: languageCode, value: "Passages are drawn from articles that people researched, wrote, and edited, each one backed by cited sources you can check.", comment: "Second paragraph of the sheet that explains searching within articles. Says where the passages come from.")
    private(set) lazy var learnMoreTitle = CommonStrings.learnMoreTitle(languageCode: languageCode)

    /// The sheet lays out in the direction of the search language, not of the app language.
    var isRightToLeft: Bool {
        guard let languageCode else {
            return false
        }
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft
    }

    public init(languageCode: String?, learnMoreAction: @escaping Action, closeAction: @escaping Action) {
        self.languageCode = languageCode
        self.learnMoreAction = learnMoreAction
        self.closeAction = closeAction
        let example = WMFSemanticSearchInfoExample.forLanguage(languageCode)
        self.exampleQuery = example.query
        self.exampleResult = WMFSemanticSearchResultViewModel(
            exampleResult: example.result,
            project: example.project,
            thumbnail: example.thumbnail,
            attribution: example.attribution,
            localizedStrings: .forLanguage(languageCode)
        )
    }

    func learnMore() {
        learnMoreAction()
    }

    func close() {
        closeAction()
    }
}
