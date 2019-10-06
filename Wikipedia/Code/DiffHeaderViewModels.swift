
import Foundation


struct DiffHeaderViewModel {
    
    enum DiffHeaderType {
        case singleRevision(editorViewModel: DiffHeaderEditorViewModel, summaryViewModel: DiffHeaderEditSummaryViewModel)
        case compareRevision(DiffHeaderCompareViewModel)
    }
    
    let title: DiffHeaderTitleViewModel
    let type: DiffHeaderType
    
    var isExtendedViewHidingEnabled: Bool {
        switch type {
        case .compareRevision:
            return false
        case .singleRevision:
            return true
        }
    }
    
    init(type: DiffContainerViewModel.DiffType, fromModel: StubRevisionModel, toModel: StubRevisionModel, theme: Theme) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let formatString: String
        let titleViewModel: DiffHeaderTitleViewModel
        switch type {
        case .single(let byteDifference):
            formatString = "HH:mm zzz, dd MMM yyyy"
            dateFormatter.dateFormat = formatString
            let heading = (toModel.timestamp as NSDate).wmf_localizedRelativeDateStringFromLocalDateToNow()
            let title = dateFormatter.string(from: toModel.timestamp)
            let subtitle: String
            if byteDifference < 0 {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-removed", value:"{{PLURAL:%1$d|%1$d byte removed|%1$d bytes removed}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were removed in this revision."), byteDifference)
            } else {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-added", value:"{{PLURAL:%1$d|%1$d byte added|%1$d bytes added}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were added in this revision."), byteDifference)
            }
            
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: title, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.boldSubheadline, subtitleColor: theme.colors.accent)
            
            let summaryViewModel = DiffHeaderEditSummaryViewModel(heading: WMFLocalizedString("diff-single-header-summary-heading", value: "Edit summary", comment: "Heading label in header summary view when viewing a single revision."), tags: [], summary: toModel.summary) //TONITODO: TAGS
            
            let editorViewModel = DiffHeaderEditorViewModel(heading: WMFLocalizedString("diff-single-header-editor-title", value: "Editor information", comment: "Title label in header editor view when viewing a single revision."), username: toModel.username, state: .loadingNumberOfEdits)
            
            self.title = titleViewModel
            self.type = .singleRevision(editorViewModel: editorViewModel, summaryViewModel: summaryViewModel)
            
        case .compare(let articleTitle, let numIntermediateRevisions, let numIntermediateEditors, let scrollYOffset, let beginSquishYOffset):
            formatString = "HH:mm, dd MMM yyyy"
            dateFormatter.dateFormat = formatString
            let heading = WMFLocalizedString("diff-compare-header-heading", value: "Compare Revisions", comment: "Heading label in header when comparing two revisions.")
            let subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-compare-header-subtitle", value:"{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}} by {{PLURAL:%1$d|%1$d user|%1$d users}} not shown", comment:"Subtitle label in header when comparing two revisions. %1$d is replaced with the number of intermediate revisions between chosen revisions to compare, and %1$d is replaced by the number of editors that made those intermediate revisions."), numIntermediateRevisions, numIntermediateEditors)
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: articleTitle, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.subheadline, subtitleColor: theme.colors.secondaryText)
            
            self.title = titleViewModel
            let compareModel = DiffHeaderCompareViewModel(fromModel: fromModel, toModel: toModel, dateFormatter: dateFormatter, theme: theme, scrollYOffset: scrollYOffset, beginSquishYOffset: beginSquishYOffset)
            self.type = .compareRevision(compareModel)
        }
    }
}

struct DiffHeaderTitleViewModel {
    let heading: String
    let title: String
    let subtitle: String
    let subtitleTextStyle: DynamicTextStyle
    let subtitleColor: UIColor
}

enum DiffHeaderTag {
    case minor //todo: populate this
}

struct DiffHeaderEditSummaryViewModel {
    let heading: String
    let tags: [DiffHeaderTag]
    let summary: String
}

struct DiffHeaderEditorViewModel {
    
    enum State {
        case loadingNumberOfEdits
        case loadedNumberOfEdits(numberOfEdits: Int)
    }
    
    let heading: String
    let username: String
    let state: State
    let numberOfEditsFormat = WMFLocalizedString("diff-single-header-editor-number-edits-format", value:"{{PLURAL:%1$d|%1$d edit|%1$d edits}}", comment:"Label to show the number of total edits made by the editor when viewing a single revision. %1$d is replaced with the editor's number of edits.")
}

struct DiffHeaderCompareViewModel {
    let fromModel: DiffHeaderCompareItemViewModel
    let toModel: DiffHeaderCompareItemViewModel
    let scrollYOffset: CGFloat
    let beginSquishYOffset: CGFloat
    
    init(fromModel: StubRevisionModel, toModel: StubRevisionModel, dateFormatter: DateFormatter, theme: Theme, scrollYOffset: CGFloat, beginSquishYOffset: CGFloat) {
        self.fromModel = DiffHeaderCompareItemViewModel(type: .from, model: fromModel, dateFormatter: dateFormatter, theme: theme)
        self.toModel = DiffHeaderCompareItemViewModel(type: .to, model: toModel, dateFormatter: dateFormatter, theme: theme)
        self.scrollYOffset = scrollYOffset
        self.beginSquishYOffset = beginSquishYOffset
    }
}

struct DiffHeaderCompareItemViewModel {
    let heading: String
    let username: String
    let tags: [DiffHeaderTag]
    let summary: String
    let timestampString: String
    let accentColor: UIColor
    
    init(type: DiffHeaderCompareType, model: StubRevisionModel, dateFormatter: DateFormatter, theme: Theme) {
        
        switch type {
        case .from:
            heading = WMFLocalizedString("diff-compare-header-from-info-heading", value: "From", comment: "Heading label in from revision info box when comparing two revisions.")
            accentColor = theme.colors.link //TONITODO: maybe new color style here?
        case .to:
            heading = WMFLocalizedString("diff-compare-header-to-info-heading", value: "From", comment: "Heading label in to revision info box when comparing two revisions.")
            accentColor = theme.colors.warning //TONITODO: maybe new color style here? this is not a warning label
        }
        
        self.username = model.username
        self.tags = [] //TONITODO: tags here
        self.summary = model.summary
        self.timestampString = dateFormatter.string(from: model.timestamp)
    }
}

enum DiffHeaderCompareType {
    case from
    case to
}
