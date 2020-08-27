
import Foundation

final class DiffHeaderViewModel: Themeable {
    
    enum DiffHeaderType {
        case single(editorViewModel: DiffHeaderEditorViewModel, summaryViewModel: DiffHeaderEditSummaryViewModel)
        case compare(compareViewModel: DiffHeaderCompareViewModel, navBarTitle: String)
    }
    
    var title: DiffHeaderTitleViewModel
    let diffType: DiffContainerViewModel.DiffType
    let headerType: DiffHeaderType
    private let articleTitle: String
    private let byteDifference: Int?
    static let dateFormatter = DateFormatter()
    
    var isExtendedViewHidingEnabled: Bool {
        switch headerType {
        case .compare:
            return false
        case .single:
            return true
        }
    }
    
    init?(diffType: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, articleTitle: String, byteDifference: Int?, theme: Theme) {
        
        self.diffType = diffType
        self.articleTitle = articleTitle
        self.byteDifference = byteDifference
        
        DiffHeaderViewModel.dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let formatString: String
        let titleViewModel: DiffHeaderTitleViewModel
        
        switch diffType {
        case .single:
            
            guard let byteDifference = byteDifference else {
                    return nil
            }
            
            formatString = "HH:mm zzz, dd MMM yyyy" //tonitodo: "UTC" instead of "GMT" in result?
            DiffHeaderViewModel.dateFormatter.dateFormat = formatString
            
            var heading: String?
            var title: String?
            if let toDate = toModel.revisionDate as NSDate? {
                heading = toDate.wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                title = DiffHeaderViewModel.dateFormatter.string(from: toDate as Date)
            }
            
            let subtitle: String
            if byteDifference < 0 {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-removed", value:"{{PLURAL:%1$d|%1$d byte removed|%1$d bytes removed}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were removed in this revision."), -byteDifference)
            } else {
                subtitle = String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-added", value:"{{PLURAL:%1$d|%1$d byte added|%1$d bytes added}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were added in this revision."), byteDifference)
            }
            
            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: title, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.boldSubheadline, subtitleColor: nil)
            
            let summaryViewModel = DiffHeaderEditSummaryViewModel(heading: WMFLocalizedString("diff-single-header-summary-heading", value: "Edit summary", comment: "Heading label in header summary view when viewing a single revision."), isMinor: toModel.isMinor, summary: toModel.parsedComment)
            
            let editorViewModel = DiffHeaderEditorViewModel(heading: WMFLocalizedString("diff-single-header-editor-title", value: "Editor information", comment: "Title label in header editor view when viewing a single revision."), username: toModel.user)
            
            self.title = titleViewModel
            self.headerType = .single(editorViewModel: editorViewModel, summaryViewModel: summaryViewModel)
            
        case .compare:
            
            guard let fromModel = fromModel else {
                return nil
            }
            
            titleViewModel = DiffHeaderViewModel.generateTitleViewModelForCompare(articleTitle: articleTitle, editCounts: nil)
            
            self.title = titleViewModel
            
            let formatString = "HH:mm, dd MMM yyyy"
            DiffHeaderViewModel.dateFormatter.dateFormat = formatString
            
            let compareModel = DiffHeaderCompareViewModel(fromModel: fromModel, toModel: toModel, dateFormatter: DiffHeaderViewModel.dateFormatter, theme: theme)
            let navBarTitle = WMFLocalizedString("diff-compare-title", value: "Compare Revisions", comment: "Title label that shows in the navigation bar when scrolling and comparing revisions.")
            self.headerType = .compare(compareViewModel: compareModel, navBarTitle: navBarTitle)
        }
        
        apply(theme: theme)
    }
    
    static func generateTitleViewModelForCompare(articleTitle: String, editCounts: EditCountsGroupedByType?) -> DiffHeaderTitleViewModel {
        let heading = CommonStrings.compareRevisionsTitle
        let subtitle: String?

        if let editCounts = editCounts {
            switch (editCounts[.edits], editCounts[.editors]) {
            case (let edits?, let editors?):
                
                if edits.count == 0 && editors.count == 0 {
                    subtitle = nil
                    break
                }
                
                switch (edits.limit, editors.limit) {
                case (false, false):
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-editors-count", value: "{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}} by {{PLURAL:%2$d|%2$d user|%2$d users}} not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. It also includes the number of editors who created those revisions. %1$d is replaced with the number of intermediate revisions and %2$d is replaced with the number of editors who created those revisions."), edits.count, editors.count)
                case (true, true):
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-editors-count-limited", value: "%1$d+ intermediate revisions by %2$d+ users not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. It also includes the number of editors who created those revisions. %1$d is replaced with the number of intermediate revisions and %2$d is replaced with the number of editors who created those revisions. The numbers are followed by the '+' to indicate that the actual numbers exceed the displayed numbers."), edits.count, editors.count)
                case (true, false):
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-limited-editors-count", value: "%1$d+ intermediate revisions by {{PLURAL:%2$d|%2$d user|%2$d users}} not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. It also includes the number of editors who created those revisions. %1$d is replaced with the number of intermediate revisions and %2$d is replaced with the number of editors who created those revisions. The number of intermediate revisions is followed by the '+' to indicate that the actual number of intermediate revisions exceeds the displayed number."), edits.count, editors.count)
                case (false, true):
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-editors-limited-count", value: "{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}} by %2$d+ users not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. It also includes the number of editors who created those revisions. %1$d is replaced with the number of intermediate revisions and %2$d is replaced with the number of editors who created those revisions. The number of editors is followed by the '+' to indicate that the actual number of editors exceeds the displayed number."), edits.count, editors.count)
                }
            case (let edits?, nil):
                
                if edits.count == 0 {
                    subtitle = nil
                    break
                }
                
                if edits.limit {
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-count-limited", value: "%1$d+ intermediate revisions not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. %1$d is replaced with the number of intermediate revisions. The number of intermediate revisions is followed by the '+' to indicate that the actual number of revisions exceeds the displayed number."), edits.count)
                } else {
                    subtitle = String.localizedStringWithFormat(WMFLocalizedString("intermediate-edits-count", value: "{{PLURAL:%1$d|%1$d intermediate revision|%1$d intermediate revisions}} not shown", comment: "Subtitle for the number of revisions that were made between two chosen revisions. %1$d is replaced with the number of intermediate revisions."), edits.count)
                }
            default:
                subtitle = nil
                break
            }
        } else {
            subtitle = nil
        }
        
        return DiffHeaderTitleViewModel(heading: heading, title: articleTitle, subtitle: subtitle, subtitleTextStyle: DynamicTextStyle.subheadline, subtitleColor: nil)
    }
    
    func apply(theme: Theme) {
        switch diffType {
        case .single:
            if let byteDifference = byteDifference,
                byteDifference < 0 {
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
    let subtitle: String?
    let subtitleTextStyle: DynamicTextStyle
    var subtitleColor: UIColor?
    
    init(heading: String?, title: String?, subtitle: String?, subtitleTextStyle: DynamicTextStyle, subtitleColor: UIColor?) {
        self.heading = heading?.localizedUppercase
        self.title = title
        self.subtitle = subtitle
        self.subtitleTextStyle = subtitleTextStyle
        self.subtitleColor = subtitleColor
    }
}

final class DiffHeaderEditSummaryViewModel {
    let heading: String
    let isMinor: Bool
    let summary: String? //tonitodo - because WMFPageHistoryRevision.parsedComment is nullable, can we make that not optional
    
    init(heading: String, isMinor: Bool, summary: String?) {
        self.heading = heading
        self.isMinor = isMinor
        self.summary = summary?.removingHTML
    }
}

final class DiffHeaderEditorViewModel {
    
    let heading: String
    let username: String? //tonitodo: because WMFPageHistoryRevision user is nullable, can we make that not nullable
    var numberOfEdits: Int? {
        didSet {
            guard let numberOfEdits = numberOfEdits else {
                return
            }
            
            //tonitodo: should we go larger than int?
            numberOfEditsForDisplay =  String.localizedStringWithFormat(numberOfEditsFormat, numberOfEdits)
        }
    }
    private(set) var numberOfEditsForDisplay: String?
    private let numberOfEditsFormat = WMFLocalizedString("diff-single-header-editor-number-edits-format", value:"{{PLURAL:%1$d|%1$d edit|%1$d edits}}", comment:"Label to show the number of total edits made by the editor when viewing a single revision. %1$d is replaced with the editor's number of edits.")
    
    init(heading: String, username: String?) {
        self.heading = heading
        self.username = username
    }
}

final class DiffHeaderCompareViewModel: Themeable {
    let fromModel: DiffHeaderCompareItemViewModel
    let toModel: DiffHeaderCompareItemViewModel
    
    init(fromModel: WMFPageHistoryRevision, toModel: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme) {
        self.fromModel = DiffHeaderCompareItemViewModel(type: .from, model: fromModel, dateFormatter: dateFormatter, theme: theme, revisionID: fromModel.revisionID)
        self.toModel = DiffHeaderCompareItemViewModel(type: .to, model: toModel, dateFormatter: dateFormatter, theme: theme, revisionID: toModel.revisionID)
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
    let isMinor: Bool
    let summary: String? //tonitodo: because WMFPageHistoryRevision.parsedComment is nullable, can we make not nullable
    let timestampString: String? //tonitodo: because WMFPageHistoryRevision.revisionDate is nullable, can we make not nullable
    var accentColor: UIColor
    let revisionID: Int
    
    init(type: DiffHeaderCompareType, model: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme, revisionID: Int) {
        
        self.type = type
        switch type {
        case .from:
            heading = WMFLocalizedString("diff-compare-header-from-info-heading", value: "From:", comment: "Heading label in from revision info box when comparing two revisions.")
        case .to:
            heading = WMFLocalizedString("diff-compare-header-to-info-heading", value: "To:", comment: "Heading label in to revision info box when comparing two revisions.")
        }
        
        self.username = model.user
        self.isMinor = model.isMinor
        self.summary = model.parsedComment?.removingHTML
        
        if let date = model.revisionDate {
            self.timestampString = dateFormatter.string(from: date)
        } else {
            self.timestampString = nil
        }
        
        self.revisionID = revisionID
        
        accentColor = theme.colors.link //compile error without this, overwrite in apply(theme:)
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        switch type {
        case .from:
            accentColor = theme.colors.link
        case .to:
            accentColor = theme.colors.diffCompareAccent
        }
    }
}

enum DiffHeaderCompareType {
    case from
    case to
}
