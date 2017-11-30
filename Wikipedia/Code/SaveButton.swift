import UIKit

@objc(WMFSaveButton) public class SaveButton: AlignedImageButton, AnalyticsContextProviding, AnalyticsContentTypeProviding {
    @objc(WMFSaveButtonState)
    public enum State: Int {
        case shortSaved
        case longSaved
        case shortSave
        case longSave
    }

    static let saveImage = UIImage(named: "unsaved", in: Bundle.wmf, compatibleWith:nil)
    static let savedImage = UIImage(named: "saved", in: Bundle.wmf, compatibleWith:nil)
    
    public var analyticsContext = "unknown"
    public var analyticsContentType = "unknown"
    
    lazy var paddingTop: CGFloat = contentEdgeInsets.top
    lazy var paddingLeft: CGFloat = contentEdgeInsets.left
    lazy var paddingBottom: CGFloat = contentEdgeInsets.bottom
    lazy var paddingRight: CGFloat = contentEdgeInsets.right
    
    convenience public init(paddingTop: CGFloat?=nil, paddingLeft: CGFloat?=nil, paddingBottom: CGFloat?=nil, paddingRight: CGFloat?=nil) {
        self.init(frame: .zero)
        
        if paddingTop != nil {
            self.paddingTop = paddingTop!
        }
        if paddingLeft != nil {
            self.paddingLeft = paddingLeft!
        }
        if paddingBottom != nil {
            self.paddingBottom = paddingBottom!
        }
        if paddingRight != nil {
            self.paddingRight = paddingRight!
        }
    }
    
    override fileprivate init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func adjustInsets() {
        super.adjustInsets()
        contentEdgeInsets = UIEdgeInsets(top: paddingTop, left: paddingLeft, bottom: paddingBottom, right: paddingRight)
    }
    
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
