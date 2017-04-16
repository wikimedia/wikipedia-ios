import Foundation

@objc protocol WMFSearchLanguagesBarViewControllerDelegate: class {
    func searchLanguagesBarViewController(controller: WMFSearchLanguagesBarViewController, didChangeCurrentlySelectedSearchLanguage language: MWKLanguageLink)
}

class WMFSearchLanguagesBarViewController: UIViewController, WMFPreferredLanguagesViewControllerDelegate, WMFLanguagesViewControllerDelegate {
    weak var delegate: WMFSearchLanguagesBarViewControllerDelegate?
    
    @IBOutlet private var languageButtons: [UIButton] = []
    @IBOutlet private var otherLanguagesButton: UIButton?
    @IBOutlet private var heightConstraint: NSLayoutConstraint?
    
    private var hidden: Bool = false {
        didSet {
            if(hidden){
                heightConstraint!.constant = 0
                view.hidden = true
            }else{
                heightConstraint!.constant = 44
                view.hidden = false
            }
        }
    }

    private(set) var currentlySelectedSearchLanguage: MWKLanguageLink? {
        get {
            if let siteURL = NSUserDefaults.wmf_userDefaults().wmf_currentSearchLanguageDomain(), selectedLanguage = MWKLanguageLinkController.sharedInstance().languageForSiteURL(siteURL) {
                return selectedLanguage
            }else{
                if let appLang:MWKLanguageLink? = MWKLanguageLinkController.sharedInstance().appLanguage {
                    self.currentlySelectedSearchLanguage = appLang
                    return appLang
                }else{
                    assert(false, "appLanguage should have been set at this point")
                    return nil
                }
            }
        }
        set {
            NSUserDefaults.wmf_userDefaults().wmf_setCurrentSearchLanguageDomain(newValue?.siteURL())
            delegate?.searchLanguagesBarViewController(self, didChangeCurrentlySelectedSearchLanguage: newValue!)
            updateLanguageBarLanguageButtons()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        for button in languageButtons {
            button.tintColor = UIColor.wmf_blueTintColor()
        }
        otherLanguagesButton?.setBackgroundImage(UIImage.wmf_imageFromColor(UIColor.whiteColor()), forState: .Normal)
        otherLanguagesButton?.setBackgroundImage(UIImage.wmf_imageFromColor(UIColor(white: 0.9, alpha: 1.0)), forState: .Highlighted)
        otherLanguagesButton?.setTitle(localizedStringForKeyFallingBackOnEnglish("main-menu-title"), forState: .Normal)
        otherLanguagesButton?.titleLabel?.font = UIFont.wmf_subtitle()

        NSNotificationCenter.defaultCenter().addObserverForName(WMFAppLanguageDidChangeNotification, object: nil, queue: nil) { notification in
            guard let langController = notification.object, appLanguage = langController.appLanguage else {
                assert(false, "Could not extract app language from WMFAppLanguageDidChangeNotification")
                return
            }
            self.currentlySelectedSearchLanguage = appLanguage
        }

        NSNotificationCenter.defaultCenter().addObserverForName(WMFPreferredLanguagesDidChangeNotification, object: nil, queue: nil) { _ in
            if let selectedLang = self.currentlySelectedSearchLanguage {
                // The selected lang won't be in languageBarLanguages() if the user has dragged it down so it's not in top 3 langs...
                if(self.languageBarLanguages().indexOf(selectedLang) == nil){
                    // ...so select first lang if the selected lang has been moved down out of the top 3.
                    self.currentlySelectedSearchLanguage = self.languageBarLanguages().first
                    // Reminder: cannot use "reorderPreferredLanguage" for this (in "didUpdatePreferredLanguages:") because
                    // that would undo the dragging the user just did and would also not work for changes made from settings.
                }
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguageBarLanguageButtons()
        hidden = !NSUserDefaults.wmf_userDefaults().wmf_showSearchLanguageBar()

        var selectedButtonCount = 0
        for button in languageButtons{
            if button.selected {
                selectedButtonCount += 1
            }
        }
//        assert(selectedButtonCount == 1, "One button should be selected by now")
    }
    
    private func languageBarLanguages() -> [MWKLanguageLink] {
        return Array(MWKLanguageLinkController.sharedInstance().preferredLanguages.prefix(3))
    }

    private func updateLanguageBarLanguageButtons(){
        for (index, language) in languageBarLanguages().enumerate() {
            if index >= languageButtons.count {
                break
            }
            let button = languageButtons[index]
            button.setTitle(language.localizedName, forState: .Normal)
            if let selectedLanguage = currentlySelectedSearchLanguage {
                button.selected = language.isEqualToLanguageLink(selectedLanguage)
            }else{
                assert(false, "selectedLanguage should have been set at this point")
                button.selected = false
            }
        }
        for(index, button) in languageButtons.enumerate(){
            if index >= languageBarLanguages().count {
                button.enabled = false
                button.hidden = true
            }else{
                button.enabled = true
                button.hidden = false
            }
        }
    }
    
    @IBAction private func setCurrentlySelectedLanguageToButtonLanguage(withSender sender: UIButton) {
        guard let buttonIndex = languageButtons.indexOf(sender) where languageBarLanguages().indices.contains(buttonIndex) else {
            assert(false, "Language button not found for language")
            return
        }
        currentlySelectedSearchLanguage = languageBarLanguages()[buttonIndex]
    }
    
    @IBAction private func openLanguagePicker() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.delegate = self
        presentViewController(UINavigationController.init(rootViewController: languagesVC), animated: true, completion: nil)
    }
    
    func languagesController(controller: WMFLanguagesViewController!, didSelectLanguage language: MWKLanguageLink!) {
        // If the selected language will not be displayed because we only display max 3 languages, move it to index 2
        if(languageBarLanguages().indexOf(language) == nil){
            MWKLanguageLinkController.sharedInstance().reorderPreferredLanguage(language, toIndex: 2)
        }
        
        currentlySelectedSearchLanguage = language
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
