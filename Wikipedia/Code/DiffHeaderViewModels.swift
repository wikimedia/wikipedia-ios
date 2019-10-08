
import Foundation

final class DiffHeaderViewModel {
    
    enum DiffHeaderType {
        case single(editorViewModel: DiffHeaderEditorViewModel, summaryViewModel: DiffHeaderEditSummaryViewModel,  byteDifference: Int)
        case compare(DiffHeaderCompareViewModel)
    }
    
    let title: DiffHeaderTitleViewModel
    let type: DiffHeaderType
    var theme: Theme {
        didSet {
            title.theme = theme
            switch type {
            case .compare(let compareViewModel):
                compareViewModel.theme = theme
            case .single(let editorViewModel, let summaryViewModel, let byteDifference):
                editorViewModel.theme = theme
                summaryViewModel.theme = theme
                if byteDifference < 0 {
                    title.subtitleColor = theme.colors.destructive
                } else {
                    title.subtitleColor = theme.colors.accent
                }
            }
        }
    }
    
    var isExtendedViewHidingEnabled: Bool {
        switch type {
        case .compare:
            return false
        case .single:
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
            formatString = "HH:mm zzz, dd MMM yyyy" //tonitodo: "UTC" instead of "GMT" in result?
            dateFormatter.dateFormat = formatString
            let heading = (toModel.timestamp as NSDate).wmf_localizedRelativeDateStringFromLocalDateToNow()
            let title = dateFormatter.string(from: toModel.timestamp)
            let subtitle: String
            let subtitleColor: UIColor
            if byteDifference < 0 {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-removed", value:"{{PLURAL:%1$d|%1$d byte removed|%1$d bytes removed}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were removed in this revision."), -byteDifference)
                subtitleColor = theme.colors.destructive
            } else {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-added", value:"{{PLURAL:%1$d|%1$d byte added|%1$d bytes added}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were added in this revision."), byteDifference)
                subtitleColor = theme.colors.accent
            }
            
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: title, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.boldSubheadline, subtitleColor: subtitleColor, theme: theme)
            
            let summaryViewModel = DiffHeaderEditSummaryViewModel(heading: WMFLocalizedString("diff-single-header-summary-heading", value: "Edit summary", comment: "Heading label in header summary view when viewing a single revision."), tags: [], summary: toModel.summary, theme: theme) //TONITODO: TAGS
            
            let editorViewModel = DiffHeaderEditorViewModel(heading: WMFLocalizedString("diff-single-header-editor-title", value: "Editor information", comment: "Title label in header editor view when viewing a single revision."), username: toModel.username, state: .loadingNumberOfEdits, theme: theme)
            
            self.title = titleViewModel
            self.type = .single(editorViewModel: editorViewModel, summaryViewModel: summaryViewModel, byteDifference: byteDifference)
            
        case .compare(let articleTitle, let numberOfIntermediateRevisions, let numberOfIntermediateUsers):
            formatString = "HH:mm, dd MMM yyyy"
            dateFormatter.dateFormat = formatString
            let heading = WMFLocalizedString("diff-compare-header-heading", value: "Compare Revisions", comment: "Heading label in header when comparing two revisions.")
            let subtitleFormat = WMFLocalizedString("diff-compare-header-subtitle-format", value:"%1$@ by %2$@ not shown", comment:"Subtitle label in header when comparing two revisions. %1$@ is replaced with the number of intermediate revisions between chosen revisions to compare, and %2$@ is replaced by the number of editors that made those intermediate revisions.")
            let numberOfIntermediateRevisionsText = String.localizedStringWithFormat(WMFLocalizedString("diff-compare-header-subtitle-num-revisions", value:"{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}}", comment:"Number of revisions text in subtitle label in header when comparing two revisions. %1$d is replaced with the number of intermediate revisions between chosen revisions to compare."), numberOfIntermediateRevisions)
            let numberOfIntermediateUsersText = String.localizedStringWithFormat(WMFLocalizedString("diff-compare-header-subtitle-num-users", value:"{{PLURAL:%1$d|%1$d user|%1$d users}}", comment:"Number of users text in subtitle label in header when comparing two revisions. %1$d is replaced with the number of users that made intermediate revisions between revisions being compared."), numberOfIntermediateUsers)
            let subtitle = String.localizedStringWithFormat(subtitleFormat, numberOfIntermediateRevisionsText, numberOfIntermediateUsersText)
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: articleTitle, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.subheadline, subtitleColor: nil, theme: theme)
            
            self.title = titleViewModel
            let compareModel = DiffHeaderCompareViewModel(fromModel: fromModel, toModel: toModel, dateFormatter: dateFormatter, theme: theme)
            self.type = .compare(compareModel)
        }
        
        self.theme = theme
    }
}

final class DiffHeaderTitleViewModel {
    let heading: String
    let title: String
    let subtitle: String
    let subtitleTextStyle: DynamicTextStyle
    var subtitleColor: UIColor?
    var theme: Theme
    
    init(heading: String, title: String, subtitle: String, subtitleTextStyle: DynamicTextStyle, subtitleColor: UIColor?, theme: Theme) {
        self.heading = heading.localizedUppercase
        self.title = title
        self.subtitle = subtitle
        self.subtitleTextStyle = subtitleTextStyle
        self.subtitleColor = subtitleColor
        self.theme = theme
    }
}

enum DiffHeaderTag {
    case minor //todo: populate this
}

final class DiffHeaderEditSummaryViewModel {
    let heading: String
    let tags: [DiffHeaderTag]
    let summary: String
    var theme: Theme
    
    init(heading: String, tags: [DiffHeaderTag], summary: String, theme: Theme) {
        self.heading = heading
        self.tags = tags
        self.summary = summary
        self.theme = theme
    }
}

final class DiffHeaderEditorViewModel {
    
    enum State {
        case loadingNumberOfEdits
        case loadedNumberOfEdits(numberOfEdits: Int)
    }
    
    let heading: String
    let username: String
    var state: State
    let numberOfEditsFormat = WMFLocalizedString("diff-single-header-editor-number-edits-format", value:"{{PLURAL:%1$d|%1$d edit|%1$d edits}}", comment:"Label to show the number of total edits made by the editor when viewing a single revision. %1$d is replaced with the editor's number of edits.")
    var theme: Theme
    
    init(heading: String, username: String, state: State, theme: Theme) {
        self.heading = heading
        self.username = username
        self.state = state
        self.theme = theme
    }
}

final class DiffHeaderCompareViewModel {
    let fromModel: DiffHeaderCompareItemViewModel
    let toModel: DiffHeaderCompareItemViewModel
    var scrollYOffset: CGFloat = 0
    var beginSquishYOffset: CGFloat = 0
    var theme: Theme {
        didSet {
            fromModel.theme = theme
            toModel.theme = theme
            fromModel.accentColor = theme.colors.link //TONITODO: maybe new color style here?
            toModel.accentColor = theme.colors.warning //TONITODO: maybe new color style here? this is not a warning label
        }
    }
    
    init(fromModel: StubRevisionModel, toModel: StubRevisionModel, dateFormatter: DateFormatter, theme: Theme) {
        self.fromModel = DiffHeaderCompareItemViewModel(type: .from, model: fromModel, dateFormatter: dateFormatter, theme: theme)
        self.toModel = DiffHeaderCompareItemViewModel(type: .to, model: toModel, dateFormatter: dateFormatter, theme: theme)
        self.theme = theme
    }
}

final class DiffHeaderCompareItemViewModel {
    let heading: String
    let username: String
    let tags: [DiffHeaderTag]
    let summary: String
    let timestampString: String
    var accentColor: UIColor
    var theme: Theme
    
    init(type: DiffHeaderCompareType, model: StubRevisionModel, dateFormatter: DateFormatter, theme: Theme) {
        
        switch type {
        case .from:
            heading = WMFLocalizedString("diff-compare-header-from-info-heading", value: "From:", comment: "Heading label in from revision info box when comparing two revisions.")
            accentColor = theme.colors.link //TONITODO: maybe new color style here?
        case .to:
            heading = WMFLocalizedString("diff-compare-header-to-info-heading", value: "To:", comment: "Heading label in to revision info box when comparing two revisions.")
            accentColor = theme.colors.warning //TONITODO: maybe new color style here? this is not a warning label
        }
        
        self.username = model.username
        self.tags = [] //TONITODO: tags here
        self.summary = model.summary
        self.timestampString = dateFormatter.string(from: model.timestamp)
        self.theme = theme
    }
}

enum DiffHeaderCompareType {
    case from
    case to
}
