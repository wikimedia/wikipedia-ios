import UIKit

@objc(WMFSaveButton) class SaveButton: AlignedImageButton {
    @objc(WMFSaveButtonState) enum State: Int {
        case shortSaved
        case longSaved
        case shortSave
        case longSave
    }
    
    static let shortSavedTitle = WMFLocalizedString("action-saved", value:"Saved", comment:"Title for the 'Unsave' action - Indicates the article is saved\n{{Identical|Saved}}")
    static let shortSaveTitle = WMFLocalizedString("action-save", value:"Save", comment:"Title for the 'Save' action\n{{Identical|Save}}")
    static let savedTitle = WMFLocalizedString("button-saved-for-later", value:"Saved for later", comment:"Longer button text for already saved button used in various places.")
    static let saveTitle = WMFLocalizedString("button-save-for-later", value:"Save for later", comment:"Longer button text for save button used in various places.")
    static let saveImage = #imageLiteral(resourceName: "places-save")
    static let savedImage = #imageLiteral(resourceName: "places-unsave")
    
    var saveButtonState: SaveButton.State = .shortSave {
        didSet {
            let saveTitle: String
            let saveImage: UIImage
            switch saveButtonState {
            case .longSaved:
                saveTitle = SaveButton.savedTitle
                saveImage = SaveButton.savedImage
            case .longSave:
                saveTitle = SaveButton.saveTitle
                saveImage = SaveButton.saveImage
            case .shortSaved:
                saveTitle = SaveButton.shortSavedTitle
                saveImage = SaveButton.savedImage
            case .shortSave:
                fallthrough
            default:
                saveTitle = SaveButton.shortSaveTitle
                saveImage = SaveButton.saveImage
            }
            setTitle(saveTitle, for: .normal)
            setImage(saveImage, for: .normal)
        }
    }
}
