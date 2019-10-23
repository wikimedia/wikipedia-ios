
import Foundation

final class DiffHeaderViewModel: Themeable {
    
    enum DiffHeaderType {
        case single(editorViewModel: DiffHeaderEditorViewModel, summaryViewModel: DiffHeaderEditSummaryViewModel)
        case compare(compareViewModel: DiffHeaderCompareViewModel, navBarTitle: String)
    }
    
    let title: DiffHeaderTitleViewModel
    let diffType: DiffContainerViewModel.DiffType
    let headerType: DiffHeaderType
    
    var isExtendedViewHidingEnabled: Bool {
        switch headerType {
        case .compare:
            return false
        case .single:
            return true
        }
    }
    
    init(diffType: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision, toModel: WMFPageHistoryRevision, theme: Theme) {
        
        self.diffType = diffType
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let formatString: String
        let titleViewModel: DiffHeaderTitleViewModel
        
        switch diffType {
        case .single(let byteDifference):
            
            formatString = "HH:mm zzz, dd MMM yyyy" //tonitodo: "UTC" instead of "GMT" in result?
            dateFormatter.dateFormat = formatString
            
            var heading: String?
            var title: String?
            if let toDate = toModel.revisionDate as NSDate? {
                heading = toDate.wmf_localizedRelativeDateStringFromLocalDateToNow()
                title = dateFormatter.string(from: toDate as Date)
            }
            
            let subtitle: String
            if byteDifference < 0 {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-removed", value:"{{PLURAL:%1$d|%1$d byte removed|%1$d bytes removed}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were removed in this revision."), -byteDifference)
            } else {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-added", value:"{{PLURAL:%1$d|%1$d byte added|%1$d bytes added}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were added in this revision."), byteDifference)
            }
            
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: title, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.boldSubheadline, subtitleColor: nil)
            
            let summaryViewModel = DiffHeaderEditSummaryViewModel(heading: WMFLocalizedString("diff-single-header-summary-heading", value: "Edit summary", comment: "Heading label in header summary view when viewing a single revision."), tags: [], summary: toModel.parsedComment) //TONITODO: TAGS
            
            let editorViewModel = DiffHeaderEditorViewModel(heading: WMFLocalizedString("diff-single-header-editor-title", value: "Editor information", comment: "Title label in header editor view when viewing a single revision."), username: toModel.user, state: .loadingNumberOfEdits)
            
            self.title = titleViewModel
            self.headerType = .single(editorViewModel: editorViewModel, summaryViewModel: summaryViewModel)
            
        case .compare(let articleTitle, let numberOfIntermediateRevisions, let numberOfIntermediateUsers):
            formatString = "HH:mm, dd MMM yyyy"
            dateFormatter.dateFormat = formatString
            let heading = WMFLocalizedString("diff-compare-header-heading", value: "Compare Revisions", comment: "Heading label in header when comparing two revisions.")
            let subtitleFormat = WMFLocalizedString("diff-compare-header-subtitle-format", value:"%1$@ by %2$@ not shown", comment:"Subtitle label in header when comparing two revisions. %1$@ is replaced with the number of intermediate revisions between chosen revisions to compare, and %2$@ is replaced by the number of editors that made those intermediate revisions.")
            let numberOfIntermediateRevisionsText = String.localizedStringWithFormat(WMFLocalizedString("diff-compare-header-subtitle-num-revisions", value:"{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}}", comment:"Number of revisions text in subtitle label in header when comparing two revisions. %1$d is replaced with the number of intermediate revisions between chosen revisions to compare."), numberOfIntermediateRevisions)
            let numberOfIntermediateUsersText = String.localizedStringWithFormat(WMFLocalizedString("diff-compare-header-subtitle-num-users", value:"{{PLURAL:%1$d|%1$d user|%1$d users}}", comment:"Number of users text in subtitle label in header when comparing two revisions. %1$d is replaced with the number of users that made intermediate revisions between revisions being compared."), numberOfIntermediateUsers)
            let subtitle = String.localizedStringWithFormat(subtitleFormat, numberOfIntermediateRevisionsText, numberOfIntermediateUsersText)
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: articleTitle, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.subheadline, subtitleColor: nil)
            
            self.title = titleViewModel
            let compareModel = DiffHeaderCompareViewModel(fromModel: fromModel, toModel: toModel, dateFormatter: dateFormatter, theme: theme)
            let navBarTitle = WMFLocalizedString("diff-compare-title", value: "Compare Revisions", comment: "Title label that shows in the navigation bar when scrolling and comparing revisions.")
            self.headerType = .compare(compareViewModel: compareModel, navBarTitle: navBarTitle)
        }
        
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        switch diffType {
        case .single(let byteDifference):
            if byteDifference < 0 {
                title.subtitleColor = theme.colors.destructive
            } else {
                title.subtitleColor = theme.colors.accent
            }
        default:
            break
        }
    }
}

final class DiffHeaderTitleViewModel {
    let heading: String? //tonitodo: because WMFPageHistoryRevision revisionDate is nullable and that's displayed as a title in single revision view, can we make it not optional. same with title
    let title: String?
    let subtitle: String
    let subtitleTextStyle: DynamicTextStyle
    var subtitleColor: UIColor?
    
    init(heading: String?, title: String?, subtitle: String, subtitleTextStyle: DynamicTextStyle, subtitleColor: UIColor?) {
        self.heading = heading?.localizedUppercase
        self.title = title
        self.subtitle = subtitle
        self.subtitleTextStyle = subtitleTextStyle
        self.subtitleColor = subtitleColor
    }
}

enum DiffHeaderTag {
    case minor //todo: populate this
}

final class DiffHeaderEditSummaryViewModel {
    let heading: String
    let tags: [DiffHeaderTag]
    let summary: String? //tonitodo - because WMFPageHistoryRevision.parsedComment is nullable, can we make that not optional
    
    init(heading: String, tags: [DiffHeaderTag], summary: String?) {
        self.heading = heading
        self.tags = tags
        self.summary = summary
    }
}

final class DiffHeaderEditorViewModel {
    
    enum State {
        case loadingNumberOfEdits
        case loadedNumberOfEdits(numberOfEdits: Int)
    }
    
    let heading: String
    let username: String? //tonitodo: because WMFPageHistoryRevision user is nullable, can we make that not nullable
    var state: State
    let numberOfEditsFormat = WMFLocalizedString("diff-single-header-editor-number-edits-format", value:"{{PLURAL:%1$d|%1$d edit|%1$d edits}}", comment:"Label to show the number of total edits made by the editor when viewing a single revision. %1$d is replaced with the editor's number of edits.")
    
    init(heading: String, username: String?, state: State) {
        self.heading = heading
        self.username = username
        self.state = state
    }
}

final class DiffHeaderCompareViewModel: Themeable {
    let fromModel: DiffHeaderCompareItemViewModel
    let toModel: DiffHeaderCompareItemViewModel
    
    init(fromModel: WMFPageHistoryRevision, toModel: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme) {
        self.fromModel = DiffHeaderCompareItemViewModel(type: .from, model: fromModel, dateFormatter: dateFormatter, theme: theme)
        self.toModel = DiffHeaderCompareItemViewModel(type: .to, model: toModel, dateFormatter: dateFormatter, theme: theme)
    }
    
    func apply(theme: Theme) {
        fromModel.apply(theme: theme)
        toModel.apply(theme: theme)
    }
}

final class DiffHeaderCompareItemViewModel: Themeable {
    let type: DiffHeaderCompareType
    let heading: String
    let username: String? //tonitodo: because WMFPageHistoryRevision.user is nullable, can we make not nullable
    let tags: [DiffHeaderTag]
    let summary: String? //tonitodo: because WMFPageHistoryRevision.parsedComment is nullable, can we make not nullable
    let timestampString: String? //tonitodo: because WMFPageHistoryRevision.revisionDate is nullable, can we make not nullable
    var accentColor: UIColor
    
    init(type: DiffHeaderCompareType, model: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme) {
        
        self.type = type
        switch type {
        case .from:
            heading = WMFLocalizedString("diff-compare-header-from-info-heading", value: "From:", comment: "Heading label in from revision info box when comparing two revisions.")
        case .to:
            heading = WMFLocalizedString("diff-compare-header-to-info-heading", value: "To:", comment: "Heading label in to revision info box when comparing two revisions.")
        }
        
        self.username = model.user
        self.tags = [] //TONITODO: tags here
        self.summary = model.parsedComment
        
        if let date = model.revisionDate {
            self.timestampString = dateFormatter.string(from: date)
        } else {
            self.timestampString = nil
        }
        
        accentColor = theme.colors.link //compile error without this, overwrite in apply(theme:)
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        switch type {
        case .from:
            accentColor = theme.colors.link //TONITODO: maybe new color style here?
        case .to:
            accentColor = theme.colors.warning //TONITODO: maybe new color style here? this is not a warning label
        }
    }
}

enum DiffHeaderCompareType {
    case from
    case to
}
