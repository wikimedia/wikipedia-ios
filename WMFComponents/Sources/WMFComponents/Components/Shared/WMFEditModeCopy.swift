import Foundation
import WMFData
import WMFNativeLocalizations

enum WMFEditModeCopy {

    static let visualEditingTitle = WMFLocalizedString("choose-editor-visual-title", value: "Visual editing", comment: "Title of the visual editing option in the choose editor sheet")
    static let visualEditingSubtitle = WMFLocalizedString("choose-editor-visual-subtitle", value: "Make changes directly to the page you see. Opens in your browser.", comment: "Subtitle of the visual editing option in the choose editor sheet")
    static let sourceEditingTitle = WMFLocalizedString("choose-editor-source-title", value: "Source editing", comment: "Title of the source editing option in the choose editor sheet")
    static let sourceEditingSubtitle = WMFLocalizedString("choose-editor-source-subtitle", value: "Make changes using markup. Stays in the app.", comment: "Subtitle of the source editing option in the choose editor sheet")
}

extension WMFEditMode {

    var localizedTitle: String {
        switch self {
        case .visual: return WMFEditModeCopy.visualEditingTitle
        case .source: return WMFEditModeCopy.sourceEditingTitle
        }
    }

    var localizedSubtitle: String {
        switch self {
        case .visual: return WMFEditModeCopy.visualEditingSubtitle
        case .source: return WMFEditModeCopy.sourceEditingSubtitle
        }
    }
}
