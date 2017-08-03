import UIKit

@objc(WMFSaveButton) public class SaveButton: AlignedImageButton, AnalyticsContextProviding, AnalyticsContentTypeProviding {
    @objc(WMFSaveButtonState)
    public enum State: Int {
        case shortSaved
        case longSaved
        case shortSave
        case longSave
    }

    static let saveImage = UIImage(named: "save", in: Bundle.wmf, compatibleWith:nil)
    static let savedImage = UIImage(named: "unsave", in: Bundle.wmf, compatibleWith:nil)
    
    public var analyticsContext = "unknown"
    public var analyticsContentType = "unknown"
    
    public var saveButtonState: SaveButton.State = .shortSave {
        didSet {
            let saveTitle: String
            let saveImage: UIImage?
            switch saveButtonState {
            case .longSaved:
                saveTitle = CommonStrings.savedTitle
                saveImage = SaveButton.savedImage
                accessibilityLabel = CommonStrings.accessibilitySavedTitle
            case .longSave:
                saveTitle = CommonStrings.saveTitle
                saveImage = SaveButton.saveImage
                accessibilityLabel = CommonStrings.saveTitle
            case .shortSaved:
                saveTitle = CommonStrings.shortSavedTitle
                saveImage = SaveButton.savedImage
                accessibilityLabel = CommonStrings.accessibilitySavedTitle
            case .shortSave:
                fallthrough
            default:
                saveTitle = CommonStrings.shortSaveTitle
                saveImage = SaveButton.saveImage
                accessibilityLabel = CommonStrings.saveTitle
            }
            UIView.performWithoutAnimation {
                setTitle(saveTitle, for: .normal)
                setImage(saveImage, for: .normal)
                layoutIfNeeded()
            }
        }
    }
}
