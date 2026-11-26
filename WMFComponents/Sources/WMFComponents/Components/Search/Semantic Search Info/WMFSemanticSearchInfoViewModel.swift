import Foundation
import UIKit
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFSemanticSearchInfoViewModel: ObservableObject {

    public typealias Action = @MainActor @Sendable () -> Void

    /// Which experiment the sheet explains. The interleaved list adds a button that turns the feature off.
    /// Without an action, the sheet hides the button.
    public enum Kind {
        case semanticSearchSheet
        case interleavedResults(turnOffAction: Action?)
    }

    let languageCode: String?
    let kind: Kind
    let exampleQuery: String
    let exampleResult: WMFSemanticSearchResultViewModel
    /// The same example, drawn as a card of the interleaved list.
    let exampleInterleavedRow: WMFSearchResultInterleavedRowViewModel
    let exampleThumbnail: UIImage?

    private let learnMoreAction: Action
    private let closeAction: Action

    private(set) lazy var title = WMFLocalizedString("search-semantic-info-title", languageCode: languageCode, value: "What is this feature?", comment: "Title of the sheet that explains searching within articles. Opens from the info button of the semantic search entry point.")
    private(set) lazy var summary = switch kind {
    case .semanticSearchSheet:
        semanticSearchSheetSummary
    case .interleavedResults:
        WMFLocalizedString("search-interleaved-info-summary", languageCode: languageCode, value: "Some results include passages drawn from articles that people researched, wrote, and edited, each one backed by cited sources you can check.", comment: "First paragraph of the sheet that explains search results that can include passages from inside articles.")
    }
    private(set) lazy var sourcesDescription = switch kind {
    case .semanticSearchSheet:
        semanticSearchSheetSourcesDescription
    case .interleavedResults:
        WMFLocalizedString("search-interleaved-info-experiment", languageCode: languageCode, value: "This is an experiment to help us improve search.", comment: "Second paragraph of the sheet that explains search results that can include passages from inside articles.")
    }
    private(set) lazy var turnOffTitle = WMFLocalizedString("search-interleaved-info-turn-off", languageCode: languageCode, value: "Turn feature off", comment: "Button of the sheet that explains search results that can include passages from inside articles. Opens the search settings, where the reader can turn the feature off.")
    private lazy var semanticSearchSheetSummary = WMFLocalizedString("search-semantic-info-summary", languageCode: languageCode, value: "Find answers to your questions inside Wikipedia articles and jump straight into the relevant passage.", comment: "First paragraph of the sheet that explains searching within articles.")
    private lazy var semanticSearchSheetSourcesDescription = WMFLocalizedString("search-semantic-info-sources", languageCode: languageCode, value: "Passages are drawn from articles that people researched, wrote, and edited, each one backed by cited sources you can check.", comment: "Second paragraph of the sheet that explains searching within articles. Says where the passages come from.")
    private(set) lazy var learnMoreTitle = CommonStrings.learnMoreTitle(languageCode: languageCode)

    /// The sheet lays out in the direction of the search language, not of the app language.
    var isRightToLeft: Bool {
        guard let languageCode else {
            return false
        }
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft
    }

    public init(languageCode: String?, kind: Kind = .semanticSearchSheet, learnMoreAction: @escaping Action, closeAction: @escaping Action) {
        self.languageCode = languageCode
        self.kind = kind
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
        self.exampleThumbnail = example.thumbnail
        self.exampleInterleavedRow = Self.interleavedRow(for: example)
    }

    var showsInterleavedResultsContent: Bool {
        switch kind {
        case .semanticSearchSheet:
            false
        case .interleavedResults:
            true
        }
    }

    /// Only the interleaved list has the button, and only when it has an action.
    var showsTurnOffButton: Bool {
        switch kind {
        case .interleavedResults(let turnOffAction):
            turnOffAction != nil
        case .semanticSearchSheet:
            false
        }
    }

    private static func interleavedRow(for example: WMFSemanticSearchInfoExample) -> WMFSearchResultInterleavedRowViewModel {
        let result = WMFSearchResultsViewModel.SearchResult(
            articleURL: example.project.siteURL ?? URL(fileURLWithPath: "/"),
            pageTitle: example.result.title,
            title: example.result.title,
            titleHTML: example.result.title,
            description: example.result.description,
            extract: WMFSemanticSearchSnippet.plainText(html: example.result.snippetHTML),
            sectionTitle: example.result.sectionTitle,
            thumbnailURL: nil)
        return WMFSearchResultInterleavedRowViewModel(
            result: result,
            project: example.project,
            showsLastUpdatedInPlaceOfReferences: example.attribution.lastUpdated != nil,
            attributionProvider: { [attribution = example.attribution] _, _ in attribution },
            attributionState: .loaded(example.attribution))
    }

    func learnMore() {
        learnMoreAction()
    }

    func close() {
        closeAction()
    }

    func turnOff() {
        switch kind {
        case .interleavedResults(let turnOffAction?):
            turnOffAction()
        case .semanticSearchSheet, .interleavedResults(nil):
            break
        }
    }
}
