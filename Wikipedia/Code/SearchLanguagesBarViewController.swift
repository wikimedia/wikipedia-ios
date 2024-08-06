import WMFComponents
import WMF

@objc protocol SearchLanguagesBarViewControllerDelegate: AnyObject {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeSelectedSearchContentLanguageCode contentLanguageCode: String)
}

class SearchLanguageButton: UnderlineButton {

    // MARK: - Properties

    var contentLanguageCode: String?
    var languageCode: String? {
        didSet {
            // Truncate to a max of 4 characters, discarding any trailing punctuation
            if let truncatedLanguageCode = languageCode?.localizedUppercase.prefix(4) {
                languageCodeLabel.text = truncatedLanguageCode.last?.isPunctuation ?? false
                    ? String(truncatedLanguageCode.dropLast())
                    : String(truncatedLanguageCode)
            }
        }
    }
    
    // MARK: - UI Elements

    private lazy var languageCodeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var languageCodeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.baselineAdjustment = .alignCenters
        label.font = WMFFont.for(.boldSubheadline)
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func setup() {
        super.setup()

        guard let titleLabel = titleLabel else {
            return
        }
        
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontForContentSizeCategory = true

        addSubview(languageCodeContainer)
        languageCodeContainer.addSubview(languageCodeLabel)
        
        let languageCodeContainerDimensionsConstraint = languageCodeContainer.widthAnchor.constraint(equalTo: languageCodeContainer.heightAnchor)
        languageCodeContainerDimensionsConstraint.priority = .required
        
        NSLayoutConstraint.activate([
            languageCodeContainer.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -6),
            languageCodeContainer.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            languageCodeContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            languageCodeContainerDimensionsConstraint,
            languageCodeLabel.centerYAnchor.constraint(equalTo: languageCodeContainer.centerYAnchor),
            languageCodeLabel.centerXAnchor.constraint(equalTo: languageCodeContainer.centerXAnchor),
            languageCodeLabel.leadingAnchor.constraint(equalTo: languageCodeContainer.leadingAnchor, constant: 2),
            languageCodeLabel.trailingAnchor.constraint(equalTo: languageCodeContainer.trailingAnchor, constant: -2)
        ])

        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        
        var deprecatedSelf = self as DeprecatedButton
        let titleEdgeInsets = deprecatedSelf.deprecatedTitleEdgeInsets
        deprecatedSelf.deprecatedTitleEdgeInsets = UIEdgeInsets(
            top: titleEdgeInsets.top,
            left: titleEdgeInsets.left + (isRTL ? 4 : 18),
            bottom: titleEdgeInsets.bottom,
            right: titleEdgeInsets.right + (isRTL ? 18 : 4)
        )
    }
    
    // MARK: - Configuration

    func apply(theme: Theme) {
        setTitleColor(theme.colors.tertiaryText, for: .normal)
        setTitleColor(theme.colors.link, for: .selected)
        tintColor = isSelected ? theme.colors.link : theme.colors.tertiaryText
        languageCodeContainer.backgroundColor = isSelected ? theme.colors.link : theme.colors.tertiaryText
        languageCodeLabel.textColor = theme.colors.paperBackground
    }
    
}

class SearchLanguagesBarViewController: ThemeableViewController, WMFPreferredLanguagesViewControllerDelegate, WMFLanguagesViewControllerDelegate {
    required init() {
        super.init(nibName: "SearchLanguagesBarViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc weak var delegate: SearchLanguagesBarViewControllerDelegate?

    @IBOutlet fileprivate var otherLanguagesButton: UIButton?
    @IBOutlet weak var otherLanguagesButtonBackgroundView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: WMFGradientView!

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 8
        return stackView
    }()

    fileprivate var selectedSearchContentLanguageCode: String? {
        get {
            if let contentLanguageCode = UserDefaults.standard.wmf_currentSearchContentLanguageCode() {
                return contentLanguageCode
            } else {
                
                if let appContentLanguageCode = MWKDataStore.shared().languageLinkController.appLanguage?.contentLanguageCode {
                    self.selectedSearchContentLanguageCode = appContentLanguageCode
                    return appContentLanguageCode
                } else {
                    assertionFailure("appLanguage should have been set at this point")
                    return nil
                }
            }
        }
        set {
            UserDefaults.standard.wmf_setCurrentSearchContentLanguageCode(newValue)
            delegate?.searchLanguagesBarViewController(self, didChangeSelectedSearchContentLanguageCode: newValue!)
            updateSearchLanguageButtons()
        }
    }
    
    var selectedSiteURL: URL? {
        let selectedLanguageLink = languageBarLanguages().first { $0.contentLanguageCode == selectedSearchContentLanguageCode }
        return selectedLanguageLink?.siteURL
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        otherLanguagesButton?.setTitle(WMFLocalizedString("main-menu-title", value:"More", comment:"Title for menu of secondary items. {{Identical|More}}"), for: .normal)
        otherLanguagesButton?.titleLabel?.font = WMFFont.for(.subheadline)

        if let otherLanguagesButton {
            var deprecatedOtherLanguagesButton = otherLanguagesButton as DeprecatedButton
            deprecatedOtherLanguagesButton.deprecatedTitleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        }
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange(_:)), name: NSNotification.Name.WMFAppLanguageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredLanguagesDidChange(_:)), name: NSNotification.Name.WMFPreferredLanguagesDidChange, object: nil)

        addSearchLanguageButtonStackView()

        apply(theme: theme)
        view.wmf_configureSubviewsForDynamicType()

        let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.startPoint = isRTL ? CGPoint(x: 0.7, y: 0) : .zero
        gradientView.endPoint = isRTL ? .zero : CGPoint(x: 0.7, y: 0)
        gradientView.isUserInteractionEnabled = false

        scrollView.clipsToBounds = true
    }

    fileprivate func addSearchLanguageButtonStackView() {
        scrollView.addSubview(stackView)

        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let defaultContentInset: CGFloat = 8
        let gradientFrameInset = gradientView.frame.size.width / 1.5
        let preferredLeftInset = isRTL ? gradientFrameInset : defaultContentInset
        let preferredRightInset = isRTL ? defaultContentInset : gradientFrameInset

        scrollView.contentInset = UIEdgeInsets(top: 0, left: preferredLeftInset, bottom: 0, right: preferredRightInset)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: preferredLeftInset, bottom: -5, right: preferredRightInset)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSearchLanguageButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showMoreLanguagesTooltipIfNecessary()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showMoreLanguagesTooltip), object: nil)
    }
    
    fileprivate func languageBarLanguages() -> [MWKLanguageLink] {
        return MWKDataStore.shared().languageLinkController.preferredLanguages
    }

    fileprivate func searchLanguageButtons() -> [SearchLanguageButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? SearchLanguageButton }
    }
    
    fileprivate func updateSearchLanguageButtons() {
        guard let currentlySelectedContentLanguageCode = selectedSearchContentLanguageCode else {
            assertionFailure("No current app content language code")
            return
        }

        stackView.subviews.forEach { $0.removeFromSuperview() }

        for language in languageBarLanguages() {
            let button = SearchLanguageButton()

            button.languageCode = language.languageCode
            button.contentLanguageCode = language.contentLanguageCode
            button.isSelected = language.contentLanguageCode == currentlySelectedContentLanguageCode
            button.addTarget(self, action: #selector(setCurrentlySelectedLanguageToButtonLanguage(withSender:)), for: .primaryActionTriggered)
            button.setTitle((language.name as NSString).wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: nil), for: .normal)

            stackView.addArrangedSubview(button)
        }

        scrollToSelectedSearchLanguageButton()
        apply(theme: theme)
    }

    fileprivate func scrollToSelectedSearchLanguageButton() {
        guard let selectedButton = searchLanguageButtons().first(where: { $0.isSelected }) else {
            return
        }

        view.layoutIfNeeded()
        scrollView.scrollRectToVisible(selectedButton.frame, animated: true)
    }

    fileprivate func showMoreLanguagesTooltipIfNecessary() {
        guard !view.isHidden && languageBarLanguages().count >= 2 && !UserDefaults.standard.wmf_didShowMoreLanguagesTooltip() else {
            return
        }
        self.perform(#selector(showMoreLanguagesTooltip), with: nil, afterDelay: 1.0)
    }
    
    @objc fileprivate func showMoreLanguagesTooltip() {
        guard let button = otherLanguagesButton else {
            return
        }
        self.wmf_presentDynamicHeightPopoverViewController(sourceRect: button.convert(button.bounds, to: self.view), title: WMFLocalizedString("more-languages-tooltip-title", value:"Add languages", comment:"Title for tooltip explaining the 'More' button may be tapped to add more languages."), message: WMFLocalizedString("more-languages-tooltip-description", value:"Search Wikipedia in over 300 languages", comment:"Description for tooltip explaining the 'More' button may be tapped to add more languages."), width: 230, duration: 3)
        UserDefaults.standard.wmf_setDidShowMoreLanguagesTooltip(true)
    }
    
    @objc fileprivate func setCurrentlySelectedLanguageToButtonLanguage(withSender sender: SearchLanguageButton) {
        guard let senderLanguage = languageBarLanguages().first(where: { $0.contentLanguageCode == sender.contentLanguageCode }) else {
            assertionFailure("Language for button not found")
            return
        }

        selectedSearchContentLanguageCode = senderLanguage.contentLanguageCode
    }
    
    @IBAction fileprivate func openLanguagePicker() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.delegate = self
        if let themeable = languagesVC as Themeable? {
            themeable.apply(theme: self.theme)
        }
        present(WMFThemeableNavigationController(rootViewController: languagesVC, theme: self.theme), animated: true, completion: nil)
    }
    
    func languagesController(_ controller: WMFLanguagesViewController, didSelectLanguage language: MWKLanguageLink) {
        // If the selected language will not be displayed because we only display max 3 languages, move it to index 2
        if languageBarLanguages().firstIndex(of: language) == nil && languageBarLanguages().count > 2 {
            MWKDataStore.shared().languageLinkController.reorderPreferredLanguage(language, to: 2)
        }
        
        selectedSearchContentLanguageCode = language.contentLanguageCode
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func appLanguageDidChange(_ notification: Notification) {
        guard let langController = notification.object, let appLanguage = (langController as AnyObject).appLanguage else {
            assertionFailure("Could not extract app language from WMFAppLanguageDidChangeNotification")
            return
        }
        selectedSearchContentLanguageCode = appLanguage?.contentLanguageCode
    }
    
    @objc func preferredLanguagesDidChange(_ notification: Notification) {
        updateSearchLanguageButtons()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        let bgColor = theme.colors.paperBackground
        view.backgroundColor = bgColor
        for languageButton in searchLanguageButtons() {
            languageButton.apply(theme: theme)
        }
        gradientView.setStart(bgColor.withAlphaComponent(0), end: bgColor)
        otherLanguagesButtonBackgroundView?.backgroundColor = bgColor
        otherLanguagesButton?.setTitleColor(theme.colors.link, for: .normal)
    }
}
