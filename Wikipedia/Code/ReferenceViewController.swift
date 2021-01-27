import Foundation

protocol ReferenceViewControllerDelegate: class {
    var referenceWebViewBackgroundTapGestureRecognizer: UITapGestureRecognizer { get }
    func referenceViewControllerUserDidTapClose(_ vc: ReferenceViewController)
    func referenceViewControllerUserDidNavigateBackToReference(_ vc: ReferenceViewController)
}

class ReferenceViewController: ViewController {
    weak var delegate: ReferenceViewControllerDelegate?
    
    var referenceId: String? = nil
    var referenceLinkText: String? = nil {
        didSet {
            updateTitle()
        }
    }
    
    func updateTitle() {
        guard let referenceLinkText = referenceLinkText else {
            return
        }
        let titleFormat = WMFLocalizedString("article-reference-view-title", value: "Reference %@", comment: "Title for the reference view. %@ is replaced by the reference link name, for example [1].")
        navigationItem.title = String.localizedStringWithFormat(titleFormat, referenceLinkText)
    }
    
    func setupNavbar() {
        navigationBar.displayType = .modal
        updateTitle()
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.leftBarButtonItem = backToReferenceButton
        apply(theme: self.theme)
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        navigationMode = .forceBar
        super.viewDidLoad()
        setupNavbar()
    }
    
    // MARK: Actions
    
    lazy var backToReferenceButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "references"), style: .plain, target: self, action: #selector(goBackToReference))
        button.accessibilityLabel = WMFLocalizedString("reference-section-button-accessibility-label", value: "Jump to reference section", comment: "Voiceover label for the top button (that jumps to article's reference section) when viewing a reference's details")
        return button
    }()
    lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "close-inverse"), style: .plain, target: self, action: #selector(closeButtonPressed))
        button.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return button
    }()

    @objc func closeButtonPressed() {
        delegate?.referenceViewControllerUserDidTapClose(self)
    }
    
    @objc func goBackToReference() {
        delegate?.referenceViewControllerUserDidNavigateBackToReference(self)
    }
    
    // MARK: Theme
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        closeButton.tintColor = theme.colors.secondaryText
        backToReferenceButton.tintColor = theme.colors.link
    }
}
