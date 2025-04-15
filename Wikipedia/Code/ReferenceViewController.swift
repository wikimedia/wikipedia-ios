import Foundation

protocol ReferenceViewControllerDelegate: AnyObject {
    var referenceWebViewBackgroundTapGestureRecognizer: UITapGestureRecognizer { get }
    func referenceViewControllerUserDidTapClose(_ vc: ReferenceViewController)
    func referenceViewControllerUserDidNavigateBackToReference(_ vc: ReferenceViewController)
}

class ReferenceViewController: ThemeableViewController {
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
    
    private lazy var customNavigationBar: UINavigationBar = {
        let navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        return navigationBar
    }()
    
    func setupCustomNavbar() {
        updateTitle()
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.leftBarButtonItem = backToReferenceButton
        
        view.addSubview(customNavigationBar)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: customNavigationBar.topAnchor),
            view.leadingAnchor.constraint(equalTo: customNavigationBar.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: customNavigationBar.trailingAnchor)
        ])
        
        customNavigationBar.items = [navigationItem]
        
        // Insert UIView covering below navigation bar, but above collection view. This hides collection view content beneath safe area.
        let overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = theme.colors.paperBackground
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: overlayView.topAnchor),
            view.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: overlayView.bottomAnchor)
        ])
        
        apply(theme: self.theme)
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomNavbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // MARK: Actions
    
    lazy var backToReferenceButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(named: "references"), style: .plain, target: self, action: #selector(goBackToReference))
        button.accessibilityLabel = WMFLocalizedString("reference-section-button-accessibility-label", value: "Jump to reference section", comment: "Voiceover label for the top button (that jumps to article's reference section) when viewing a reference's details")
        return button
    }()
    lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: CommonStrings.doneTitle, style: .plain, target: self, action: #selector(closeButtonPressed))
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
        closeButton.tintColor = theme.colors.link
        backToReferenceButton.tintColor = theme.colors.link
        
        customNavigationBar.setBackgroundImage(theme.navigationBarBackgroundImage, for: .default)
        customNavigationBar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        customNavigationBar.isTranslucent = false
        customNavigationBar.barTintColor = theme.colors.chromeBackground
        customNavigationBar.shadowImage = theme.navigationBarShadowImage
        customNavigationBar.tintColor = theme.colors.chromeText
    }
}
