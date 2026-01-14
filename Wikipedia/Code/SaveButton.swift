import UIKit

@objc(WMFSaveButtonDelegate) public protocol SaveButtonDelegate {
    func saveButtonDidReceiveLongPress(_ saveButton: SaveButton)
    func saveButtonDidReceiveAddToReadingListAction(_ saveButton: SaveButton) -> Bool
}

@objc(WMFSaveButton) public class SaveButton: AlignedImageButton, MEPEventsProviding {


    @objc(WMFSaveButtonState)
    public enum SaveButtonState: Int {
        case shortSaved
        case longSaved
        case shortSave
        case longSave
    }

    static let saveImage = UIImage(named: "unsaved", in: Bundle.wmf, compatibleWith:nil)
    static let savedImage = UIImage(named: "saved", in: Bundle.wmf, compatibleWith:nil)

    public var eventLoggingCategory: EventCategoryMEP = .feed
    public var eventLoggingLabel: EventLabelMEP? = nil

    public var showImage: Bool = true
    public var showTitle: Bool = true

    public var saveButtonState: SaveButton.SaveButtonState = .shortSave {
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
                horizontalSpacing = 8
                accessibilityLabel = CommonStrings.accessibilitySavedTitle
            case .shortSave:
                fallthrough
            default:
                saveTitle = CommonStrings.shortSaveTitle
                saveImage = SaveButton.saveImage
                horizontalSpacing = 8
                accessibilityLabel = CommonStrings.saveTitle
            }
            let addToReadingListAction = UIAccessibilityCustomAction(name: CommonStrings.addToReadingListActionTitle, target: self, selector: #selector(addToReadingList(_:)))
            accessibilityCustomActions = [addToReadingListAction]
            if showTitle {
                setTitle(saveTitle, for: .normal)
            }
            if showImage {
                setImage(saveImage, for: .normal)
            }
            var deprecatedSelf = self as DeprecatedButton
            deprecatedSelf.deprecatedAdjustsImageWhenHighlighted = false
        }
    }
    
    @objc func addToReadingList(_ sender: UIControl) -> Bool {
        return saveButtonDelegate?.saveButtonDidReceiveAddToReadingListAction(self) ?? false
    }
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    public weak var saveButtonDelegate: SaveButtonDelegate? {
        didSet {
            if let lpgr = longPressGestureRecognizer, saveButtonDelegate == nil {
                removeGestureRecognizer(lpgr)
            } else if saveButtonDelegate != nil && longPressGestureRecognizer == nil {
                let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
                addGestureRecognizer(lpgr)
                longPressGestureRecognizer = lpgr
            }
        }
    }
    
    @objc public func handleLongPressGestureRecognizer(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else {
            return
        }
        saveButtonDelegate?.saveButtonDidReceiveLongPress(self)
    }
}
