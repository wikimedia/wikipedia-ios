import UIKit

@objc protocol SearchLanguagesBarViewControllerDelegate: class {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeCurrentlySelectedSearchLanguage language: MWKLanguageLink)
}

class SearchLanguageButton: UnderlineButton {
    var contentLanguageCode: String?

    override func setup() {
        super.setup()
        titleLabel?.numberOfLines = 1
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
    }
}

class SearchLanguagesBarViewController: UIViewController, WMFPreferredLanguagesViewControllerDelegate, WMFLanguagesViewControllerDelegate, Themeable {
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

    @objc var theme: Theme = Theme.standard
    
    @objc fileprivate(set) var currentlySelectedSearchLanguage: MWKLanguageLink? {
        get {
            if let contentLanguageCode = UserDefaults.standard.wmf_currentSearchContentLanguageCode(), let selectedLanguage = MWKDataStore.shared().languageLinkController.language(forContentLanguageCode: contentLanguageCode) {
                return selectedLanguage
            } else {
                
                if let appLang = MWKDataStore.shared().languageLinkController.appLanguage {
                    self.currentlySelectedSearchLanguage = appLang
                    return appLang
                } else {
                    assertionFailure("appLanguage should have been set at this point")
                    return nil
                }
            }
        }
        set {
            UserDefaults.standard.wmf_setCurrentSearchContentLanguageCode(newValue?.contentLanguageCode)
            delegate?.searchLanguagesBarViewController(self, didChangeCurrentlySelectedSearchLanguage: newValue!)
            updateSearchLanguageButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        otherLanguagesButton?.setTitle(WMFLocalizedString("main-menu-title", value:"More", comment:"Title for menu of secondary items. {{Identical|More}}"), for: .normal)
        otherLanguagesButton?.titleLabel?.font = UIFont.wmf_font(.subheadline)
        otherLanguagesButton?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        
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

        scrollView.clipsToBounds = false
    }

    fileprivate func addSearchLanguageButtonStackView() {
        scrollView.addSubview(stackView)

        stackView.leadingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: scrollView.leadingAnchor, multiplier: 2).isActive = true

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: gradientView.frame.size.width)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: -5, right: gradientView.frame.size.width)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSearchLanguageButtons()
        assert(searchLanguageButtons().filter { $0.isSelected }.count == 1)
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
        guard let currentlySelectedLanguage = currentlySelectedSearchLanguage else {
            assertionFailure("No current app language")
            return
        }

        stackView.subviews.forEach { $0.removeFromSuperview() }

        for language in languageBarLanguages() {
            let button = SearchLanguageButton()

            button.contentLanguageCode = language.contentLanguageCode
            button.isSelected = language.contentLanguageCode == currentlySelectedLanguage.contentLanguageCode
            button.addTarget(self, action: #selector(setCurrentlySelectedLanguageToButtonLanguage(withSender:)), for: .primaryActionTriggered)
            button.setTitle(language.localizedName, for: .normal)

            stackView.addArrangedSubview(button)
        }

        apply(theme: theme)
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
        self.wmf_presentDynamicHeightPopoverViewController(forSourceRect: button.convert(button.bounds, to: self.view), withTitle: WMFLocalizedString("more-languages-tooltip-title", value:"Add languages", comment:"Title for tooltip explaining the 'More' button may be tapped to add more languages."), message: WMFLocalizedString("more-languages-tooltip-description", value:"Search Wikipedia in over 300 languages", comment:"Description for tooltip explaining the 'More' button may be tapped to add more languages."), width: 230.0, duration: 3.0)
        UserDefaults.standard.wmf_setDidShowMoreLanguagesTooltip(true)
    }
    
    @objc fileprivate func setCurrentlySelectedLanguageToButtonLanguage(withSender sender: SearchLanguageButton) {
        guard let senderLanguage = languageBarLanguages().first(where: { $0.contentLanguageCode == sender.contentLanguageCode }) else {
            assertionFailure("Language for button not found")
            return
        }

        currentlySelectedSearchLanguage = senderLanguage
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
        if(languageBarLanguages().firstIndex(of: language) == nil && languageBarLanguages().count > 2){
            MWKDataStore.shared().languageLinkController.reorderPreferredLanguage(language, to: 2)
        }
        
        currentlySelectedSearchLanguage = language
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func appLanguageDidChange(_ notification: Notification) {
        guard let langController = notification.object, let appLanguage = (langController as AnyObject).appLanguage else {
            assertionFailure("Could not extract app language from WMFAppLanguageDidChangeNotification")
            return
        }
        currentlySelectedSearchLanguage = appLanguage
    }
    
    @objc func preferredLanguagesDidChange(_ notification: Notification) {
        if let selectedLang = currentlySelectedSearchLanguage {
            // The selected lang won't be in languageBarLanguages() if the user has dragged it down so it's not in top 3 langs...
            if(languageBarLanguages().firstIndex(of: selectedLang) == nil){
                // ...so select first lang if the selected lang has been moved down out of the top 3.
                currentlySelectedSearchLanguage = languageBarLanguages().first
                // Reminder: cannot use "reorderPreferredLanguage" for this (in "didUpdatePreferredLanguages:") because
                // that would undo the dragging the user just did and would also not work for changes made from settings.
            } else {
                updateSearchLanguageButtons()
            }
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        let bgColor = theme.colors.paperBackground
        view.backgroundColor = bgColor
        for languageButton in searchLanguageButtons() {
            languageButton.setTitleColor(theme.colors.primaryText, for: .normal)
            languageButton.tintColor = theme.colors.link
        }
        gradientView.setStart(bgColor.withAlphaComponent(0), end: bgColor)
        otherLanguagesButtonBackgroundView?.backgroundColor = bgColor
        otherLanguagesButton?.setTitleColor(theme.colors.link, for: .normal)
    }
}
