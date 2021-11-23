
import UIKit

protocol DiffToolbarViewDelegate: AnyObject {
    func tappedPrevious()
    func tappedNext()
    func tappedShare(_ sender: UIBarButtonItem)
    func tappedThankButton()
    var isLoggedIn: Bool { get }
}

class DiffToolbarView: UIView {
    
    var parentViewState: DiffContainerViewModel.State? {
        didSet {
            apply(theme: theme)
        }
    }
    
    private var theme: Theme = .standard
    
    @IBOutlet private var toolbar: UIToolbar!
    @IBOutlet var contentView: UIView!
    lazy var previousButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "chevron-down", target: self, action: #selector(tappedPrevious(_:)), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("action-previous-revision-accessibility", value: "Previous Revision", comment: "Accessibility title for the 'Previous Revision' action button when viewing a single revision diff.")
        item.customView?.widthAnchor.constraint(equalToConstant: 38).isActive = true
        return item
    }()

    lazy var nextButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "chevron-up", target: self, action: #selector(tappedNext(_:)), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("action-next-revision-accessibility", value: "Next Revision", comment: "Accessibility title for the 'Next Revision' action button when viewing a single revision diff.")
        item.customView?.widthAnchor.constraint(equalToConstant: 38).isActive = true
        return item
    }()

    lazy var shareButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "share", target: self, action: #selector(tappedShare(_:)), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.accessibilityShareTitle

        return item
    }()

    lazy var thankButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "diff-smile", target: self, action: #selector(tappedThank(_:)), for: .touchUpInside , iconInsets: UIEdgeInsets(top: 5.0, left: 0, bottom: -5.0, right: 0))
        item.accessibilityLabel = WMFLocalizedString("action-thank-user-accessibility", value: "Thank User", comment: "Accessibility title for the 'Thank User' action button when viewing a single revision diff.")
        
        return item
    }()
    
    weak var delegate: DiffToolbarViewDelegate?
    var isThankSelected = false {
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
        
        setItems()
    }
    
   @objc func tappedPrevious(_ sender: UIBarButtonItem) {
        delegate?.tappedPrevious()
    }
    
    @objc func tappedNext(_ sender: UIBarButtonItem) {
        delegate?.tappedNext()
    }
    
    @objc func tappedShare(_ sender: UIBarButtonItem) {
        delegate?.tappedShare(shareButton)
    }
    
    @objc func tappedThank(_ sender: UIBarButtonItem) {
        delegate?.tappedThankButton()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setItems()
    }

    private func setItems() {
        let trailingMarginSpacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            trailingMarginSpacing.width = 58
        default:
            trailingMarginSpacing.width = 24
        }
        
        let leadingMarginSpacing = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
        case (.regular, .regular):
            leadingMarginSpacing.width = 42
        default:
            leadingMarginSpacing.width = 0
        }
        
        let largeFixedSize = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        largeFixedSize.width = 30
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [leadingMarginSpacing, nextButton, previousButton, spacer, thankButton, largeFixedSize, shareButton, trailingMarginSpacing]
    }
    
    func setPreviousButtonState(isEnabled: Bool) {
        previousButton.isEnabled = isEnabled
    }
    
    func setNextButtonState(isEnabled: Bool) {
        nextButton.isEnabled = isEnabled
    }
    
    func setThankButtonState(isEnabled: Bool) {
        thankButton.isEnabled = isEnabled
    }
    
    func setShareButtonState(isEnabled: Bool) {
        shareButton.isEnabled = isEnabled
    }
}

extension DiffToolbarView: Themeable {
    func apply(theme: Theme) {
        
        self.theme = theme
        
        toolbar.isTranslucent = false
        
        toolbar.backgroundColor = theme.colors.chromeBackground
        toolbar.barTintColor = theme.colors.chromeBackground
        contentView.backgroundColor = theme.colors.chromeBackground
        
        //avoid toolbar disappearing when empty/error states are shown
        if theme == Theme.black {
            switch parentViewState {
            case .error, .empty:
                    toolbar.backgroundColor = theme.colors.paperBackground
                    toolbar.barTintColor = theme.colors.paperBackground
                    contentView.backgroundColor = theme.colors.paperBackground
            default:
                break
            }
        }
        
        previousButton.apply(theme: theme)
        nextButton.apply(theme: theme)
        shareButton.apply(theme: theme)
        thankButton.apply(theme: theme)
        
        if let delegate = delegate,
            !delegate.isLoggedIn {
            if let button = thankButton.customView as? UIButton {
                button.tintColor = theme.colors.disabledLink
            }
        }
        shareButton.tintColor = theme.colors.link
    }
}
