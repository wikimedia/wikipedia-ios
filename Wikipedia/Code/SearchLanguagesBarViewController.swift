import Foundation

@objc protocol SearchLanguagesBarViewControllerDelegate: class {
    func searchLanguagesBarViewController(_ controller: SearchLanguagesBarViewController, didChangeCurrentlySelectedSearchLanguage language: MWKLanguageLink)
}

class SearchLanguageButton: UnderlineButton {
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
    
    @IBOutlet fileprivate var languageButtons: [SearchLanguageButton] = []
    @IBOutlet fileprivate var otherLanguagesButton: UIButton?
    @IBOutlet weak var otherLanguagesButtonBackgroundView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var gradientView: WMFGradientView!
    
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
            updateLanguageBarLanguageButtons()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        otherLanguagesButton?.setTitle(WMFLocalizedString("main-menu-title", value:"More", comment:"Title for menu of secondary items. {{Identical|More}}"), for: .normal)
        otherLanguagesButton?.titleLabel?.font = UIFont.wmf_font(.subheadline)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange(_:)), name: NSNotification.Name.WMFAppLanguageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredLanguagesDidChange(_:)), name: NSNotification.Name.WMFPreferredLanguagesDidChange, object: nil)
        
        apply(theme: theme)
        view.wmf_configureSubviewsForDynamicType()
        
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        gradientView.startPoint = isRTL ? CGPoint(x: 1, y: 0) : .zero
        gradientView.endPoint = isRTL ? .zero : CGPoint(x: 1, y: 0)
        
        scrollView.clipsToBounds = false
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
        updateLanguageBarLanguageButtons()
        
        var selectedButtonCount = 0
        for button in languageButtons{
            if button.isSelected {
                selectedButtonCount += 1
            }
        }
        assert(selectedButtonCount == 1, "One button should be selected by now")
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
        return Array(MWKDataStore.shared().languageLinkController.preferredLanguages.prefix(3))
    }
    
    fileprivate func updateLanguageBarLanguageButtons(){
        for (index, language) in languageBarLanguages().enumerated() {
            if index >= languageButtons.count {
                break
            }
            let button = languageButtons[index]
            button.setTitle(language.localizedName, for: .normal)
            if let selectedLanguage = currentlySelectedSearchLanguage {
                button.isSelected = language.contentLanguageCode == selectedLanguage.contentLanguageCode
            }else{
                assertionFailure("selectedLanguage should have been set at this point")
                button.isSelected = false
            }
        }
        for(index, button) in languageButtons.enumerated(){
            if index >= languageBarLanguages().count {
                button.isEnabled = false
                button.isHidden = true
            }else{
                button.isEnabled = true
                button.isHidden = false
            }
        }
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
    
    @IBAction fileprivate func setCurrentlySelectedLanguageToButtonLanguage(withSender sender: SearchLanguageButton) {
        guard let buttonIndex = languageButtons.firstIndex(of: sender), languageBarLanguages().indices.contains(buttonIndex) else {
            assertionFailure("Language button not found for language")
            return
        }
        currentlySelectedSearchLanguage = languageBarLanguages()[buttonIndex]
    }
    
    @IBAction fileprivate func openLanguagePicker() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC?.delegate = self
        if let themeable = languagesVC as Themeable? {
            themeable.apply(theme: self.theme)
        }
        present(WMFThemeableNavigationController(rootViewController: languagesVC!, theme: self.theme), animated: true, completion: nil)
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
                updateLanguageBarLanguageButtons()
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
        for languageButton in languageButtons {
            languageButton.setTitleColor(theme.colors.primaryText, for: .normal)
            languageButton.tintColor = theme.colors.link
        }
        gradientView.setStart(bgColor.withAlphaComponent(0), end: bgColor)
        otherLanguagesButtonBackgroundView?.backgroundColor = bgColor
    }
}
