import WMF
import WMFData
import WMFComponents

protocol EditorNavigationItemControllerDelegate: AnyObject {
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapTemporaryAccountNoticesButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapIPAccountNoticesButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem)
}

class EditorNavigationItemController: NSObject, Themeable {
    weak var navigationItem: UINavigationItem?
    weak var navigationBar: UINavigationBar?
    
    let dataStore: MWKDataStore
    
    internal var authManager: WMFAuthenticationManager {
       return dataStore.authenticationManager
   }

    var readingThemesControlsToolbarItem: UIBarButtonItem {
        return showingOverflow ? overflowButton : readingThemesControlsButton
    }

    init(navigationItem: UINavigationItem, navigationBar: UINavigationBar?, dataStore: MWKDataStore) {
        self.navigationItem = navigationItem
        self.navigationBar = navigationBar
        self.dataStore = dataStore
        super.init()
        configureInitialNavigationButtonItems()
    }

    func apply(theme: Theme) {
        progressButton.tintColor = theme.colors.navigationBarTintColor
        undoButton.tintColor = theme.colors.inputAccessoryButtonTint
        redoButton.tintColor = theme.colors.inputAccessoryButtonTint
        editNoticesButton.tintColor = theme.colors.diffCompareAccent
        activeTemporaryAccountNoticesButton.tintColor = theme.colors.inputAccessoryButtonTint
        temporaryAccountNoticesButton.tintColor = theme.colors.destructive
        readingThemesControlsButton.tintColor = theme.colors.inputAccessoryButtonTint
        (separatorButton.customView as? UIImageView)?.tintColor = theme.colors.newBorder
    }

    weak var delegate: EditorNavigationItemControllerDelegate?
    
    private var showingOverflow: Bool = false

    private(set) lazy var progressButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(progress(_:)))
        return button
    }()

    private(set) lazy var redoButton: UIBarButtonItem = {
        let redoButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .redo), style: .plain, target: self, action: #selector(redo))
        redoButton.accessibilityLabel = CommonStrings.redo
        return redoButton
    }()

    private(set) lazy var undoButton: UIBarButtonItem = {
        let undoButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .undo), style: .plain, target: self, action: #selector(undo))
        undoButton.accessibilityLabel = CommonStrings.undo
        return undoButton
    }()

    private lazy var editNoticesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .exclamationMarkCircleFill), style: .plain, target: self, action: #selector(editNotices(_:)))
        button.accessibilityLabel = CommonStrings.editNotices
        return button
    }()
    
    private lazy var activeTemporaryAccountNoticesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFIcon.temp, style: .plain, target: self, action: #selector(temporaryAccount(_ :)))
        button.accessibilityLabel = WMFLocalizedString("edit-sheet-temp-account-notice", value: "Temporary Account Notice", comment: "Temporary account sheet for editors")
        return button
    }()
    
    private lazy var temporaryAccountNoticesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .temporaryAccountIcon), style: .plain, target: self, action: #selector(ipAccount(_ :)))
        button.accessibilityLabel = WMFLocalizedString("edit-sheet-ip-account-notice", value: "IP Account Notice", comment: "Temporary account sheet for editors")
        return button
    }()
    
    private lazy var readingThemesControlsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .textFormatSize), style: .plain, target: self, action: #selector(showReadingThemesControls))
        button.accessibilityLabel = CommonStrings.readingThemesControls
        return button
    }()

    private lazy var separatorButton: UIBarButtonItem = {
        let width = (1.0 / UIScreen.main.scale) * 2
        let image = UIImage.roundedRectImage(with: .black, cornerRadius: 0, width: width, height: 32)?.withRenderingMode(.alwaysTemplate)
        let button = UIBarButtonItem(customView: UIImageView(image: image))
        button.isEnabled = false
        button.isAccessibilityElement = false
        return button
    }()
    
    lazy var overflowButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        return button
    }()
    
    var overflowMenu: UIMenu {
        let undo = UIAction(
            title: CommonStrings.undo,
            image: WMFSFSymbolIcon.for(symbol: .undo),
            handler: { [weak self] _ in
                self?.undo()
        })
        
        let redo = UIAction(
            title: CommonStrings.redo,
            image: WMFSFSymbolIcon.for(symbol: .redo),
            handler: { [weak self] _ in
                self?.redo()
        })
        
        let readingThemes = UIAction(
            title: CommonStrings.readingThemesControls,
            image: WMFSFSymbolIcon.for(symbol: .textFormatSize),
            handler: { [weak self] _ in
                self?.showReadingThemesControls()
        })
        
        let mainMenu = UIMenu(title: String(), children: [undo, redo, readingThemes])

        return mainMenu
    }

    @objc private func progress(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapProgressButton: sender)
    }
    
    @objc private func temporaryAccount(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapTemporaryAccountNoticesButton: activeTemporaryAccountNoticesButton)
    }
    
    @objc private func ipAccount(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapIPAccountNoticesButton: temporaryAccountNoticesButton)
    }

    @objc private func undo() {
        delegate?.editorNavigationItemController(self, didTapUndoButton: showingOverflow ? overflowButton : undoButton)
    }

    @objc private func redo() {
        delegate?.editorNavigationItemController(self, didTapRedoButton: showingOverflow ? overflowButton : redoButton)
    }

    @objc private func editNotices(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapEditNoticesButton: sender)
    }
    
    @objc private func showReadingThemesControls() {
        delegate?.editorNavigationItemController(self, didTapReadingThemesControlsButton: showingOverflow ? overflowButton : readingThemesControlsButton)
    }

    func addEditNoticesButton() {
        
        var proposedItems = initialProposedNavigationButtonItems()
        proposedItems.append(editNoticesButton)
        
        updateNavigationButtonItems(proposedItems: proposedItems, traitCollection: UITraitCollection.current)
    }
    
    func addTempAccountsNoticesButtons(wikiHasTempAccounts: Bool?) {
        
        var proposedItems = initialProposedNavigationButtonItems()
        
        guard let wikiHasTempAccounts, wikiHasTempAccounts, !authManager.authStateIsPermanent else { return }
        if authManager.authStateIsTemporary {
            proposedItems.append(activeTemporaryAccountNoticesButton)
        } else {
            proposedItems.append(temporaryAccountNoticesButton)
        }
        
        updateNavigationButtonItems(proposedItems: proposedItems, traitCollection: UITraitCollection.current)
    }
    
    private func initialProposedNavigationButtonItems() -> [UIBarButtonItem] {
        var proposedItems: [UIBarButtonItem] = []
        if #available(iOS 26.0, *) {
            
            proposedItems = [
                progressButton,
                readingThemesControlsButton,
                redoButton,
                undoButton
            ]
        } else {
            let fixedWidthSpacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixedWidthSpacer.width = 16
            
            proposedItems = [
                progressButton,
                fixedWidthSpacer,
                separatorButton,
                readingThemesControlsButton,
                redoButton,
                undoButton
            ]
        }
        
        return proposedItems
    }

    private func configureInitialNavigationButtonItems() {
        
        let proposedItems = initialProposedNavigationButtonItems()
        
        updateNavigationButtonItems(proposedItems: proposedItems, traitCollection: UITraitCollection.current)
    }
    
    private func shouldCollapseToOverflow(proposedItems: [UIBarButtonItem], traitCollection: UITraitCollection) -> Bool {
        
        let availableWidth = navigationBar?.bounds.width ?? UIScreen.main.bounds.width
        
        if #available(iOS 26.0, *) {
            switch traitCollection.preferredContentSizeCategory {
            case .large, .medium, .small, .extraSmall:
                return availableWidth <= 400 && proposedItems.count > 4
            default:
                return traitCollection.horizontalSizeClass == .compact
            }
        } else {
            return false
        }
    }
    
    private func updateNavigationButtonItems(proposedItems: [UIBarButtonItem], traitCollection: UITraitCollection) {
        if #available(iOS 26.0, *) {
            if shouldCollapseToOverflow(proposedItems: proposedItems, traitCollection: traitCollection) {
                var finalItems = proposedItems
                let progressButton = finalItems.removeFirst()
                finalItems.removeSubrange(0...2)
                
                finalItems.insert(progressButton, at: 0)
                finalItems.insert(overflowButton, at: 1)
                
                navigationItem?.rightBarButtonItems = finalItems
                
                showingOverflow = true
                
            } else {
                navigationItem?.rightBarButtonItems = proposedItems
                showingOverflow = false
            }
        } else {
            navigationItem?.rightBarButtonItems = proposedItems
        }
    }

    func textSelectionDidChange(isRangeSelected: Bool) {
        undoButton.isEnabled = true
        redoButton.isEnabled = true
        progressButton.isEnabled = true
    }

    func disableButton(button: EditorButton) {
        switch button.kind {
        case .undo:
            undoButton.isEnabled = false
        case .redo:
            redoButton.isEnabled = false
        case .progress:
            progressButton.isEnabled = false
        }
    }
}
