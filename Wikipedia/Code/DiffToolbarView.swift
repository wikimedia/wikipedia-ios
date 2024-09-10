import UIKit

protocol DiffToolbarViewDelegate: AnyObject {
    func tappedPrevious()
    func tappedNext()
    func tappedShare()
    func tappedThankButton()
    func tappedUndo()
    func tappedRollback()
    func tappedEditHistory()
    func tappedWatch()
    func tappedUnwatch()
    var isPermanent: Bool { get }
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

    lazy var moreButton: IconBarButtonItem = {
        return createMoreButton()
    }()

    lazy var undoButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "Revert", target: self, action: #selector(tappedUndo(_:)), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.undo
        return item
    }()

    lazy var thankButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "diff-smile", target: self, action: #selector(tappedThank(_:)), for: .touchUpInside , iconInsets: UIEdgeInsets(top: 2.0, left: 0, bottom: -2.0, right: 0))
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

    @objc func tappedUndo(_ sender: UIBarButtonItem) {
        delegate?.tappedUndo()
    }

    @objc func tappedRollback() {
        delegate?.tappedRollback()
    }
    
    @objc func tappedPrevious(_ sender: UIBarButtonItem) {
        delegate?.tappedPrevious()
    }
    
    @objc func tappedNext(_ sender: UIBarButtonItem) {
        delegate?.tappedNext()
    }
    
    @objc func tappedShare() {
        delegate?.tappedShare()
    }
    
    @objc func tappedWatch() {
        delegate?.tappedWatch()
    }
    
    @objc func tappedUnwatch() {
        delegate?.tappedUnwatch()
    }

    @objc func tappedEditHistory() {
        delegate?.tappedEditHistory()
    }
    
    @objc func tappedThank(_ sender: UIBarButtonItem) {
        delegate?.tappedThankButton()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setItems()
    }
    
    func updateMoreButton(needsRollbackButton: Bool? = nil, needsWatchButton: Bool = false, needsUnwatchHalfButton: Bool = false, needsUnwatchFullButton: Bool = false, needsArticleEditHistoryButton: Bool = false) {
        
        let resolvedNeedsRollback = needsRollbackButton ?? currentlyHasRollback ?? false
        self.moreButton = createMoreButton(needsRollbackButton: resolvedNeedsRollback, needsWatchButton: needsWatchButton, needsUnwatchHalfButton: needsUnwatchHalfButton, needsUnwatchFullButton: needsUnwatchFullButton, needsArticleEditHistoryButton: needsArticleEditHistoryButton)
        setItems()
    }
    
    private var currentlyHasRollback: Bool?
    private func createMoreButton(needsRollbackButton: Bool = false, needsWatchButton: Bool = false, needsUnwatchHalfButton: Bool = false, needsUnwatchFullButton: Bool = false, needsArticleEditHistoryButton: Bool = false) -> IconBarButtonItem {
        
        var actions: [UIAction] = []
        if needsRollbackButton {
            actions.append(UIAction(title: CommonStrings.rollback, image: UIImage(systemName: "arrow.uturn.backward.circle"), attributes: [.destructive], handler: { [weak self] _ in self?.tappedRollback() }))
        }
        currentlyHasRollback = needsRollbackButton
        actions.append(UIAction(title: CommonStrings.shortShareTitle, image: UIImage(systemName: "square.and.arrow.up"), handler: { [weak self] _ in self?.tappedShare()}))

       if needsWatchButton {
           actions.append(UIAction(title: CommonStrings.watch, image: UIImage(systemName: "star"), handler: { [weak self] _ in self?.tappedWatch() }))
       } else if needsUnwatchHalfButton {
           actions.append(UIAction(title: CommonStrings.unwatch, image: UIImage(systemName: "star.leadinghalf.filled"), handler: { [weak self] _ in self?.tappedUnwatch()}))
       } else if needsUnwatchFullButton {
           actions.append(UIAction(title: CommonStrings.unwatch, image: UIImage(systemName: "star.fill"), handler: { [weak self] _ in self?.tappedUnwatch()}))
       }
           
       if needsArticleEditHistoryButton {
           actions.append(UIAction(title: CommonStrings.diffArticleEditHistory, image: UIImage(named: "edit-history"), handler: { [weak self] _ in self?.tappedEditHistory() }))
       }
        
        let menu = UIMenu(title: "", options: .displayInline, children: actions)
        
        let item = IconBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: menu)

        item.accessibilityLabel = CommonStrings.moreButton
        return item
    }
    
    var moreButtonSourceView: UIView {
        return self
    }
    
    var moreButtonSourceRect: CGRect? {
        
        guard let undoButtonView = undoButton.customView,
              let thankButtonView = thankButton.customView else {
            return nil
        }
        
        return WatchlistController.calculateToolbarFifthButtonSourceRect(toolbarView: self, thirdButtonView: undoButtonView, fourthButtonView: thankButtonView)
    }

    private func setItems() {
        let flexibleSpace = UIBarButtonItem.flexibleSpaceToolbar()

        toolbar.items = [flexibleSpace, nextButton, flexibleSpace, previousButton, flexibleSpace, undoButton, flexibleSpace, thankButton, flexibleSpace, moreButton, flexibleSpace]
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

    func setMoreButtonState(isEnabled: Bool) {
        moreButton.isEnabled = isEnabled
    }
}

extension DiffToolbarView: Themeable {
    func apply(theme: Theme) {
        
        self.theme = theme
        
        toolbar.isTranslucent = false
        
        toolbar.backgroundColor = theme.colors.chromeBackground
        toolbar.barTintColor = theme.colors.chromeBackground
        contentView.backgroundColor = theme.colors.chromeBackground
        
        // avoid toolbar disappearing when empty/error states are shown
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
        undoButton.apply(theme: theme)
        thankButton.apply(theme: theme)
        moreButton.apply(theme: theme)

        if let delegate = delegate,
            !delegate.isPermanent {
            if let button = thankButton.customView as? UIButton {
                button.tintColor = theme.colors.disabledLink
            }
        }
    }
}
