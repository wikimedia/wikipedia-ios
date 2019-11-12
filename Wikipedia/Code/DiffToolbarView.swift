
import UIKit

protocol DiffToolbarViewDelegate: class {
    func tappedPrevious()
    func tappedNext()
    func tappedShare(_ sender: UIView?)
    func tappedThank(isAlreadySelected: Bool, isLoggedIn: Bool)
}

class DiffToolbarView: UIView {
    
    @IBOutlet private var toolbar: UIToolbar!
    @IBOutlet var contentView: UIView!
    lazy var previousButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "chevron-up", target: self, action: #selector(tappedPrevious(_:)), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("action-previous-revision-accessibility", value: "Previous Revision", comment: "Accessibility title for the 'Previous Revision' action button when viewing a single revision diff.")
        return item
    }()

    lazy var nextButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "chevron-down", target: self, action: #selector(tappedNext(_:)), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("action-next-revision-accessibility", value: "Next Revision", comment: "Accessibility title for the 'Next Revision' action button when viewing a single revision diff.")
        return item
    }()

    lazy var shareButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "share", target: self, action: #selector(tappedShare(_:)), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.accessibilityShareTitle
        return item
    }()

    lazy var thankButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "diff-smile", target: self, action: #selector(tappedThank(_:)), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("action-thank-user-accessibility", value: "Thank User", comment: "Accessibility title for the 'Thank User' action button when viewing a single revision diff.")
        if let button = item.customView as? UIButton {
            button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 0, bottom: 0, right: 0)
        }
        return item
    }()
    
    weak var delegate: DiffToolbarViewDelegate?
    private var isThankSelected = false {
        didSet {
            
            let imageName = isThankSelected ? "diff-smile-filled" : "diff-smile"
            if let button = thankButton.customView as? UIButton {
                button.setImage(UIImage(named: imageName), for: .normal)
            }
        }
    }
    
    var toolbarHeight: CGFloat {
        return toolbar.frame.height
    }
    
    private var isLoggedIn: Bool {
        return WMFAuthenticationManager.sharedInstance.isLoggedIn
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed(DiffToolbarView.wmf_nibName(), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let smallFixedSize = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        smallFixedSize.width = 10
        
        let largeFixedSize = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        largeFixedSize.width = 15
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [largeFixedSize, previousButton, smallFixedSize, nextButton, spacer, thankButton, largeFixedSize, shareButton, largeFixedSize]
    }
    
   @objc func tappedPrevious(_ sender: UIBarButtonItem) {
        delegate?.tappedPrevious()
    }
    
    @objc func tappedNext(_ sender: UIBarButtonItem) {
        delegate?.tappedNext()
    }
    
    @objc func tappedShare(_ sender: UIBarButtonItem) {
        delegate?.tappedShare(sender.customView)
    }
    
    @objc func tappedThank(_ sender: UIBarButtonItem) {
        delegate?.tappedThank(isAlreadySelected: isThankSelected, isLoggedIn: isLoggedIn)
        
        if isLoggedIn {
            isThankSelected = true
        }
    }
    
    func setPreviousButtonState(isEnabled: Bool) {
        
    }
    
    func setNextButtonState(isEnabled: Bool) {
        
    }
    
    func setThankButtonState(isEnabled: Bool) {
        
    }
}

extension DiffToolbarView: Themeable {
    func apply(theme: Theme) {
        toolbar.isTranslucent = false
        toolbar.backgroundColor = theme.colors.chromeBackground
        toolbar.barTintColor = theme.colors.chromeBackground
        contentView.backgroundColor = theme.colors.chromeBackground
        previousButton.apply(theme: theme)
        nextButton.apply(theme: theme)
        shareButton.apply(theme: theme)
        thankButton.apply(theme: theme)
        
        if !isLoggedIn {
            if let button = thankButton.customView as? UIButton {
                button.tintColor = theme.colors.disabledLink
            }
        }
        shareButton.tintColor = theme.colors.link
    }
}
