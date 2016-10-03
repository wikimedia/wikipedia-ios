import Foundation

@objc protocol WMFSearchLanguagesBarViewControllerDelegate: class {
    func searchLanguagesBarViewController(controller: WMFSearchLanguagesBarViewController, didChangeCurrentlySelectedSearchLanguage language: MWKLanguageLink)
}

class WMFSearchLanguagesBarViewController: UIViewController, WMFPreferredLanguagesViewControllerDelegate {
    weak var delegate: WMFSearchLanguagesBarViewControllerDelegate?
    
    @IBOutlet private var languageButtons: [UIButton] = []
    @IBOutlet private var otherLanguagesButton: UIButton?
    @IBOutlet private var heightConstraint: NSLayoutConstraint?
    
    private var previousFirstLanguage: MWKLanguageLink?
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

    private var _currentlySelectedSearchLanguage: MWKLanguageLink?
    private(set) var currentlySelectedSearchLanguage: MWKLanguageLink? {
        get {
            return _currentlySelectedSearchLanguage
        }
        set {
            _currentlySelectedSearchLanguage = newValue
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

        _currentlySelectedSearchLanguage = selectedLanguage()
        assert(_currentlySelectedSearchLanguage != nil, "Expected language not set")
        
        previousFirstLanguage = languageBarLanguages().first
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguageBarLanguageButtons()
        hidden = !NSUserDefaults.wmf_userDefaults().wmf_showSearchLanguageBar()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged()
        previousFirstLanguage = languageBarLanguages().first
    }
    
    private func languageBarLanguages() -> [MWKLanguageLink] {
        return Array(MWKLanguageLinkController.sharedInstance().preferredLanguages.prefix(3))
    }

    private func selectFirstLanguageIfNoneSelectedOrIfFirstLanguageHasChanged(){
        if(isEveryButtonUnselected() || isFirstLanguageDifferentFromLastTime()){
            setLanguage(withSender:languageButtons.first!)
        }
    }
    
    private func isEveryButtonUnselected() -> Bool{
        for button in languageButtons {
            if button.selected {
                return false
            }
        }
        return true
    }

    private func isFirstLanguageDifferentFromLastTime() -> Bool{
        guard let first = languageBarLanguages().first, previous = previousFirstLanguage else {
            return false
        }
        return !first.isEqualToLanguageLink(previous)
    }

    private func updateLanguageBarLanguageButtons(){
        for (index, language) in languageBarLanguages().enumerate() {
            if index >= languageButtons.count {
                break
            }
            let button = languageButtons[index]
            button.setTitle(language.localizedName, forState: .Normal)
            if let selectedLanguage = selectedLanguage() {
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
    
    @IBAction private func setLanguage(withSender sender: UIButton) {
        let index = languageButtons.indexOf(sender)
        assert(index != NSNotFound, "Language button not found for language")
        if (index != NSNotFound) {
            currentlySelectedSearchLanguage = languageBarLanguages()[index!]
        }
    }

    private func selectedLanguage() -> MWKLanguageLink? {
        var selectedLanguage:MWKLanguageLink?
        if let siteURL = NSUserDefaults.wmf_userDefaults().wmf_currentSearchLanguageDomain() {
            selectedLanguage = MWKLanguageLinkController.sharedInstance().languageForSiteURL(siteURL)
        }else{
            selectedLanguage = MWKLanguageLinkController.sharedInstance().appLanguage
        }
        assert(selectedLanguage != nil, "Expected language not set")
        return selectedLanguage
    }
    
    @IBAction private func openLanguagePicker() {
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.delegate = self
        presentViewController(UINavigationController.init(rootViewController: languagesVC), animated: true, completion: nil)
    }

    @objc func languagesController(controller: WMFPreferredLanguagesViewController!, didUpdatePreferredLanguages languages: [MWKLanguageLink]!) {
        updateLanguageBarLanguageButtons()
    }
}
