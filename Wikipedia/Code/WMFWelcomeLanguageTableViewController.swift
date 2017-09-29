
class WMFWelcomeLanguageTableViewController: UIViewController, WMFPreferredLanguagesViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    fileprivate var theme = Theme.standard
    
    @IBOutlet fileprivate var languageTableView:UITableView!
    @IBOutlet fileprivate var moreLanguagesButton:UIButton!
    @IBOutlet fileprivate var languagesDescriptionLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        languagesDescriptionLabel.text = WMFLocalizedString("welcome-languages-description", value:"We've detected the following languages on your device:", comment:"Title label describing detected languages")
        
        languageTableView.alwaysBounceVertical = false
        moreLanguagesButton.setTitle(WMFLocalizedString("welcome-languages-add-or-edit-button", value:"Add to, or edit your preferred languages", comment:"Title for button for managing languages"), for: .normal)
        moreLanguagesButton.setTitleColor(theme.colors.link, for: .normal)
        languageTableView.rowHeight = UITableViewAutomaticDimension
        languageTableView.estimatedRowHeight = 30
        view.wmf_configureSubviewsForDynamicType()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.wmf_userDefaults().wmf_setShowSearchLanguageBar(MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MWKLanguageLinkController.sharedInstance().preferredLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFWelcomeLanguageTableViewCell.wmf_nibName(), for: indexPath) as! WMFWelcomeLanguageTableViewCell
        let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[indexPath.row]
        cell.languageName = langLink.name
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // https://stackoverflow.com/a/3991688/135557
        cell.backgroundColor = .clear
    }
    
    @IBAction func addLanguages(withSender sender: AnyObject) {
        let langsVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        langsVC?.delegate = self
        let navC = ThemeableNavigationController(rootViewController: langsVC!, theme: Theme.standard)
        // Intentionally not using apply(theme:) for now to limit any unintended consequences elsewhere in the app
        navC.navigationBar.isTranslucent = false
        navC.view.tintColor = theme.colors.link
        //TODO: figure out why lang filter search box doesn't show if "Add another language" is tapped from this presented VC
        present(navC, animated: true, completion: nil)
    }
    
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages:[MWKLanguageLink]){
        languageTableView.reloadData()
        languageTableView.layoutIfNeeded() // Needed for the content offset reset below to work
        languageTableView.contentOffset = .zero
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        moreLanguagesButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }
}
