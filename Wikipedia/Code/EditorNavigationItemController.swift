import WMF
import WMFComponents

protocol EditorNavigationItemControllerDelegate: AnyObject {
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapProgressButton progressButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapCloseButton closeButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapUndoButton undoButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapRedoButton redoButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapReadingThemesControlsButton readingThemesControlsButton: UIBarButtonItem)
    func editorNavigationItemController(_ editorNavigationItemController: EditorNavigationItemController, didTapEditNoticesButton: UIBarButtonItem)
}

class EditorNavigationItemController: NSObject, Themeable {
    weak var navigationItem: UINavigationItem?

    var readingThemesControlsToolbarItem: UIBarButtonItem {
        return readingThemesControlsButton
    }

    init(navigationItem: UINavigationItem) {
        self.navigationItem = navigationItem
        super.init()
        configureNavigationButtonItems()
    }

    func apply(theme: Theme) {
        closeButton.tintColor = theme.colors.chromeText
        undoButton.tintColor = theme.colors.inputAccessoryButtonTint
        redoButton.tintColor = theme.colors.inputAccessoryButtonTint
        readingThemesControlsButton.tintColor = theme.colors.inputAccessoryButtonTint
        editNoticesButton.tintColor = theme.colors.inputAccessoryButtonTint
        (separatorButton.customView as? UIImageView)?.tintColor = theme.colors.newBorder
        progressButton.tintColor = theme.colors.link
    }

    weak var delegate: EditorNavigationItemControllerDelegate?
    
    private(set) lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .close), style: .plain, target: self, action: #selector(close(_ :)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private(set) lazy var progressButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(progress(_:)))
        return button
    }()

    private(set) lazy var redoButton: UIBarButtonItem = {
        let redoButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .redo), style: .plain, target: self, action: #selector(redo(_ :)))
        redoButton.accessibilityLabel = CommonStrings.redo
        return redoButton
    }()

    private(set) lazy var undoButton: UIBarButtonItem = {
        let undoButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .undo), style: .plain, target: self, action: #selector(undo(_ :)))
        undoButton.accessibilityLabel = CommonStrings.undo
        return undoButton
    }()

    private lazy var editNoticesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .exclamationMarkCircleFill), style: .plain, target: self, action: #selector(editNotices(_ :)))
        button.accessibilityLabel = CommonStrings.editNotices
        return button
    }()
    
    private lazy var readingThemesControlsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .textFormatSize), style: .plain, target: self, action: #selector(showReadingThemesControls(_ :)))
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

    @objc private func progress(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapProgressButton: sender)
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapCloseButton: sender)
    }

    @objc private func undo(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapUndoButton: undoButton)
    }

    @objc private func redo(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapRedoButton: sender)
    }

    @objc private func editNotices(_ sender: UIBarButtonItem) {
        delegate?.editorNavigationItemController(self, didTapEditNoticesButton: sender)
    }
    
    @objc private func showReadingThemesControls(_ sender: UIBarButtonItem) {
         delegate?.editorNavigationItemController(self, didTapReadingThemesControlsButton: sender)
    }

    func addEditNoticesButton() {
        navigationItem?.rightBarButtonItems?.append(contentsOf: [
            editNoticesButton
        ])
    }

    private func configureNavigationButtonItems() {

        navigationItem?.leftBarButtonItem = closeButton

        navigationItem?.rightBarButtonItems = [
            progressButton,
            UIBarButtonItem.wmf_barButtonItem(ofFixedWidth: 16),
            separatorButton,
            readingThemesControlsButton,
            redoButton,
            undoButton
        ]
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
