import UIKit

@objc(WMFSaveButton) class SaveButton: AlignedImageButton {
    static let shortSavedTitle = WMFLocalizedString("action-saved", value:"Saved", comment:"Title for the 'Unsave' action - Indicates the article is saved\n{{Identical|Saved}}")
    static let shortSaveTitle = WMFLocalizedString("action-save", value:"Save", comment:"Title for the 'Save' action\n{{Identical|Save}}")
    static let savedTitle = WMFLocalizedString("button-saved-for-later", value:"Saved for later", comment:"Longer button text for already saved button used in various places.")
    static let saveTitle = WMFLocalizedString("button-save-for-later", value:"Save for later", comment:"Longer button text for save button used in various places.")
    

    var isSaved: Bool = false {
        didSet {
            let saveTitle = isSaved ?  SaveButton.shortSavedTitle : SaveButton.shortSaveTitle
            setTitle(saveTitle, for: .normal)
            let saveImage = isSaved ? #imageLiteral(resourceName: "places-unsave") : #imageLiteral(resourceName: "places-save")
            setImage(saveImage, for: .normal)
        }
    }
}
