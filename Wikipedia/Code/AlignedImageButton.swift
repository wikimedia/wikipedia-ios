import UIKit

public class AlignedImageButton: UIButton {
    
    @IBInspectable open var margin: CGFloat = 8
    @IBInspectable open var imageIsRightAligned: Bool = false {
        didSet {
            adjustInsets()
        }
    }

    private var isImageActuallyRightAligned: Bool {
        get {
            return effectiveUserInterfaceLayoutDirection == .rightToLeft ? !imageIsRightAligned : imageIsRightAligned
        }
    }
    
    override public var effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        get {
            let superDirection: UIUserInterfaceLayoutDirection
            if #available(iOS 10.0, *) {
                superDirection = super.effectiveUserInterfaceLayoutDirection
            } else {
                superDirection = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
            }
            if imageIsRightAligned {
                if superDirection == .leftToRight {
                    return .rightToLeft
                } else {
                    return .leftToRight
                }
            } else {
                return superDirection
            }
        }
    }
    
    fileprivate func adjustInsets() {
        let inset = effectiveUserInterfaceLayoutDirection == .rightToLeft ? -0.5 * margin : 0.5 * margin
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -inset, bottom: 0, right: inset)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: -inset)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: abs(inset), bottom: 0, right: abs(inset))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        adjustInsets()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        adjustInsets()
    }
    
}
