import WMFComponents
import WMF

final class DiffHeaderViewModel: Themeable {
    
    enum DiffHeaderType {
        case single(editorViewModel: DiffHeaderEditorViewModel, summaryViewModel: DiffHeaderEditSummaryViewModel)
        case compare(compareViewModel: DiffHeaderCompareViewModel, navBarTitle: String)
    }
    
    var title: DiffHeaderTitleViewModel
    let diffType: DiffContainerViewModel.DiffType
    let headerType: DiffHeaderType
    var imageURL: URL?
    private let articleTitle: String
    private let byteDifference: Int?
    static var dateFormatter = DateFormatter()
    
    var isExtendedViewHidingEnabled: Bool {
        return true
    }

    static func byteDifferenceStringFor(value: Int) -> String {
        if value < 0 {
            return String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-removed", value:"{{PLURAL:%1$d|%1$d byte removed|%1$d bytes removed}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were removed in this revision."), -value)
        } else {
            return String.localizedStringWithFormat(WMFLocalizedString("diff-single-header-subtitle-bytes-added", value:"{{PLURAL:%1$d|%1$d byte added|%1$d bytes added}}", comment:"Subtitle label in header when viewing a revision. %1$d is replaced by the number of bytes that were added in this revision."), value)
        }

    }
    
    init?(diffType: DiffContainerViewModel.DiffType, fromModel: WMFPageHistoryRevision?, toModel: WMFPageHistoryRevision, articleTitle: String, imageURL: URL?, byteDifference: Int?, theme: Theme, project: WikimediaProject?) {
        
        self.diffType = diffType
        self.articleTitle = articleTitle
        self.imageURL = imageURL
        self.byteDifference = byteDifference
        
        DiffHeaderViewModel.dateFormatter.timeZone = TimeZone(identifier: "UTC")
        DiffHeaderViewModel.dateFormatter.dateStyle = .medium
        DiffHeaderViewModel.dateFormatter.timeStyle = .short

        let titleViewModel: DiffHeaderTitleViewModel
        
        switch diffType {
        case .single:
            
            guard let byteDifference = byteDifference else {
                    return nil
            }

            var heading: String?
            var title: String?
            if let toDate = toModel.revisionDate as NSDate? {
                heading = toDate.wmf_fullyLocalizedRelativeDateStringFromLocalDateToNow()
                title = DiffHeaderViewModel.dateFormatter.string(from: toDate as Date)
            }
            
            let subtitle = DiffHeaderViewModel.byteDifferenceStringFor(value: byteDifference)

            titleViewModel = DiffHeaderTitleViewModel(heading: heading, title: title, subtitle: subtitle, subtitleTextStyle: .boldSubheadline, subtitleColor: nil)

            let summaryViewModel = DiffHeaderEditSummaryViewModel(heading: WMFLocalizedString("diff-single-header-summary-heading", value: "Edit summary", comment: "Heading label in header summary view when viewing a single revision."), isMinor: toModel.isMinor, summary: toModel.parsedComment)
            
            let editorViewModel = DiffHeaderEditorViewModel(heading: WMFLocalizedString("diff-single-header-editor-title", value: "Editor information", comment: "Title label in header editor view when viewing a single revision."), username: toModel.user, project: project)
            
            self.title = titleViewModel
            self.headerType = .single(editorViewModel: editorViewModel, summaryViewModel: summaryViewModel)
            
        case .compare:
            
            guard let fromModel = fromModel else {
                return nil
            }
            
            titleViewModel = DiffHeaderViewModel.generateTitleViewModelForCompare(articleTitle: articleTitle, byteDifference: byteDifference)

            self.title = titleViewModel

            let compareModel = DiffHeaderCompareViewModel(fromModel: fromModel, toModel: toModel, dateFormatter: DiffHeaderViewModel.dateFormatter, theme: theme, project: project)
            let navBarTitle = WMFLocalizedString("diff-compare-title", value: "Compare Revisions", comment: "Title label that shows in the navigation bar when scrolling and comparing revisions.")
            self.headerType = .compare(compareViewModel: compareModel, navBarTitle: navBarTitle)
        }

        apply(theme: theme)
    }
    
    static func generateTitleViewModelForCompare(articleTitle: String, byteDifference: Int?) -> DiffHeaderTitleViewModel {
        let heading = CommonStrings.compareRevisionsTitle
        let subtitle = byteDifferenceStringFor(value: byteDifference ?? 0)
        return DiffHeaderTitleViewModel(heading: heading, title: articleTitle, subtitle: subtitle, subtitleTextStyle: .boldSubheadline, subtitleColor: nil)
    }
    
    func apply(theme: Theme) {
        if let byteDifference = byteDifference,
            byteDifference < 0 {
            title.subtitleColor = theme.colors.destructive
        } else {
            title.subtitleColor = theme.colors.accent
        }
    }
}

final class DiffHeaderTitleViewModel {
    let heading: String? // tonitodo: because WMFPageHistoryRevision revisionDate is nullable and that's displayed as a title in single revision view, can we make it not optional. same with title
    let title: String?
    let subtitle: String?
    let subtitleTextStyle: WMFFont
    var subtitleColor: UIColor?

    init(heading: String?, title: String?, subtitle: String?, subtitleTextStyle: WMFFont, subtitleColor: UIColor?) {
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
    let summary: String? // tonitodo - because WMFPageHistoryRevision.parsedComment is nullable, can we make that not optional
    
    init(heading: String, isMinor: Bool, summary: String?) {
        self.heading = heading
        self.isMinor = isMinor
        self.summary = summary?.removingHTML
    }
}

final class DiffHeaderEditorViewModel {
    
    let heading: String
    let username: String? // tonitodo: because WMFPageHistoryRevision user is nullable, can we make that not nullable
    var numberOfEdits: Int? {
        didSet {
            guard let numberOfEdits = numberOfEdits else {
                return
            }
            
            // tonitodo: should we go larger than int?
            numberOfEditsForDisplay =  String.localizedStringWithFormat(numberOfEditsFormat, numberOfEdits)
        }
    }
    private(set) var numberOfEditsForDisplay: String?
    private let numberOfEditsFormat = WMFLocalizedString("diff-single-header-editor-number-edits-format", value:"{{PLURAL:%1$d|%1$d edit|%1$d edits}}", comment:"Label to show the number of total edits made by the editor when viewing a single revision. %1$d is replaced with the editor's number of edits.")
    let project: WikimediaProject?
    
    init(heading: String, username: String?, project: WikimediaProject?) {
        self.heading = heading
        self.username = username
        self.project = project
    }
}

final class DiffHeaderCompareViewModel: Themeable {
    let fromModel: DiffHeaderCompareItemViewModel
    let toModel: DiffHeaderCompareItemViewModel
    let project: WikimediaProject?
    
    init(fromModel: WMFPageHistoryRevision, toModel: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme, project: WikimediaProject?) {
        self.fromModel = DiffHeaderCompareItemViewModel(type: .from, model: fromModel, dateFormatter: dateFormatter, theme: theme, revisionID: fromModel.revisionID)
        self.toModel = DiffHeaderCompareItemViewModel(type: .to, model: toModel, dateFormatter: dateFormatter, theme: theme, revisionID: toModel.revisionID)
        self.project = project
    }
    
    func apply(theme: Theme) {
        fromModel.apply(theme: theme)
        toModel.apply(theme: theme)
    }
}

final class DiffHeaderCompareItemViewModel: Themeable {
    let type: DiffHeaderCompareType
    let heading: String
    let username: String? // tonitodo: because WMFPageHistoryRevision.user is nullable, can we make not nullable
    let isMinor: Bool
    let summary: String? // tonitodo: because WMFPageHistoryRevision.parsedComment is nullable, can we make not nullable
    let timestampString: String? // tonitodo: because WMFPageHistoryRevision.revisionDate is nullable, can we make not nullable
    var accentColor: UIColor
    let revisionID: Int
    
    init(type: DiffHeaderCompareType, model: WMFPageHistoryRevision, dateFormatter: DateFormatter, theme: Theme, revisionID: Int) {
        
        self.type = type
        switch type {
        case .from:
            heading = CommonStrings.diffFromHeading
        case .to:
            heading = CommonStrings.diffToHeading
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
        
        accentColor = theme.colors.link // compile error without this, overwrite in apply(theme:)
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        switch type {
        case .from:
            accentColor = theme.colors.diffCompareAccent
        case .to:
            accentColor = theme.colors.link
        }
    }
}

enum DiffHeaderCompareType {
    case from
    case to
}
