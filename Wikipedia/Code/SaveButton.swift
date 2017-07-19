import UIKit
import WMF

@objc(WMFSaveButton) public class SaveButton: AlignedImageButton, AnalyticsContextProviding, AnalyticsContentTypeProviding {
    @objc(WMFSaveButtonState) enum State: Int {
        case shortSaved
        case longSaved
        case shortSave
        case longSave
    }

    static let saveImage = #imageLiteral(resourceName: "places-save").withRenderingMode(.alwaysTemplate)
    static let savedImage = #imageLiteral(resourceName: "places-unsave").withRenderingMode(.alwaysTemplate)
    
    public var analyticsContext = "unknown"
    public var analyticsContentType = "unknown"
    
    var saveButtonState: SaveButton.State = .shortSave {
        didSet {
            let saveTitle: String
            let saveImage: UIImage
            switch saveButtonState {
            case .longSaved:
                saveTitle = LocalizedStrings.savedTitle
                saveImage = SaveButton.savedImage
                accessibilityLabel = LocalizedStrings.accessibilitySavedTitle
            case .longSave:
                saveTitle = LocalizedStrings.saveTitle
                saveImage = SaveButton.saveImage
                accessibilityLabel = LocalizedStrings.saveTitle
            case .shortSaved:
                saveTitle = LocalizedStrings.shortSavedTitle
                saveImage = SaveButton.savedImage
                accessibilityLabel = LocalizedStrings.accessibilitySavedTitle
            case .shortSave:
                fallthrough
            default:
                saveTitle = LocalizedStrings.shortSaveTitle
                saveImage = SaveButton.saveImage
                accessibilityLabel = LocalizedStrings.saveTitle
            }
            UIView.performWithoutAnimation {
                setTitle(saveTitle, for: .normal)
                setImage(saveImage, for: .normal)
                layoutIfNeeded()
            }
        }
    }
}
