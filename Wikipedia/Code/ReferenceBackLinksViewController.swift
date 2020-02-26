protocol ReferenceBackLinksViewControllerDelegate: class {
    func referenceBackLinksViewControllerUserDidTapClose(_ referenceBackLinksViewController: ReferenceBackLinksViewController)
    func referenceBackLinksViewControllerUserDidNavigateTo(referenceBackLink: ReferenceBackLink, referenceBackLinksViewController: ReferenceBackLinksViewController)
    func referenceBackLinksViewControllerUserDidNavigateBackToReference(_ referenceBackLinksViewController: ReferenceBackLinksViewController)
}

class ReferenceBackLinksViewController: ViewController {
    weak var delegate: ReferenceBackLinksViewControllerDelegate?
    
    var index = 0
    let backLinks: [ReferenceBackLink]
    let referenceId: String
    
    init?(referenceId: String, backLinks: [ReferenceBackLink], delegate: ReferenceBackLinksViewControllerDelegate?, theme: Theme) {
        guard backLinks.count > 0 else {
            return nil
        }
        self.referenceId = referenceId
        self.backLinks = backLinks
        self.delegate = delegate
        super.init(theme: theme)
        navigationMode = .forceBar
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    var referenceLinkTitle: String {
        guard let referenceNumberString = referenceId.split(separator: "-").last else {
            return ""
        }
       return "[" + referenceNumberString + "]"
    }
    
    lazy var nextButton = UIBarButtonItem(image:UIImage(named: "directionDown"), style: .plain, target: self, action: #selector(goToNextReference))
    lazy var previousButton = UIBarButtonItem(image:UIImage(named: "directionUp"), style: .plain, target: self, action: #selector(goToPreviousReference))
    lazy var countLabel = UILabel()
    lazy var countContainer: UIView = {
        let view = UIView()
        view.wmf_addSubviewWithConstraintsToEdges(countLabel)
        return view
    }()
    lazy var countItem = UIBarButtonItem(customView: countContainer)

    func setupToolbar() {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [countItem, flexibleSpace, previousButton, nextButton]
        if backLinks.count <= 1 {
            previousButton.isEnabled = false
            nextButton.isEnabled = false
        }
        enableToolbar()
        setToolbarHidden(false, animated: false)
    }
    
    lazy var backToReferenceButton = UIBarButtonItem(image: UIImage(named: "references"), style: .plain, target: self, action: #selector(goBackToReference))
    lazy var closeButton = UIBarButtonItem(image: UIImage(named: "close-inverse"), style: .plain, target: self, action: #selector(closeButtonPressed))
    
    func setupNavbar() {
        let titleFormat = WMFLocalizedString("article-reference-view-title", value: "Reference %@", comment: "Title for the reference view. %@ is replaced by the reference link name, for example [1].")
        navigationItem.title = String.localizedStringWithFormat(titleFormat, referenceLinkTitle)
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.leftBarButtonItem = backToReferenceButton
        apply(theme: self.theme)
    }
    
    func setupTapGestureRecognizer() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(closeButtonPressed))
        view.addGestureRecognizer(tapGR)
    }
    
    let topGradientView = WMFGradientView()
    let bottomGradientView = WMFGradientView()

    func setupGradientViews() {
        topGradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topGradientView)
        let top = topGradientView.topAnchor.constraint(equalTo: view.topAnchor)
        let leading = topGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = topGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let height = topGradientView.heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([top, leading, trailing, height])
        
        bottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomGradientView)
        let bottom = bottomGradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let bLeading = bottomGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let bTrailing = bottomGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bHeight = bottomGradientView.heightAnchor.constraint(equalToConstant: 48)
        NSLayoutConstraint.activate([bottom, bLeading, bTrailing, bHeight])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        countLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientViews()
        setupNavbar()
        setupToolbar()
        setupTapGestureRecognizer()
        notifyDelegateOfNavigationToReference()
    }
    
    // MARK: Actions

    func notifyDelegateOfNavigationToReference() {

        countLabel.text = "\(index + 1)/\(backLinks.count)"
        let backLink = backLinks[index]
        delegate?.referenceBackLinksViewControllerUserDidNavigateTo(referenceBackLink: backLink, referenceBackLinksViewController: self)
    }
    
    @objc func goToNextReference() {
        if index >= backLinks.count - 1 {
            index = 0
        } else {
            index += 1
        }
        notifyDelegateOfNavigationToReference()
    }
    
    @objc func goToPreviousReference() {
        if index <= 0 {
            index = backLinks.count - 1
        } else {
            index -= 1
        }
        notifyDelegateOfNavigationToReference()
    }
    
    @objc func closeButtonPressed() {
        delegate?.referenceBackLinksViewControllerUserDidTapClose(self)
    }
    
    @objc func goBackToReference() {
        delegate?.referenceBackLinksViewControllerUserDidNavigateBackToReference(self)
    }
    
    // MARK: Theme
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        closeButton.tintColor = theme.colors.secondaryText
        backToReferenceButton.tintColor = theme.colors.link
        topGradientView.setStart(theme.colors.overlayBackground, end: .clear)
        bottomGradientView.setStart(.clear, end: theme.colors.overlayBackground)
        countLabel.textColor = theme.colors.secondaryText
        view.backgroundColor = .clear
    }
}
