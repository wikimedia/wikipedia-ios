
// https://stackoverflow.com/a/34902501/135557
class WMFWelcomeLanguageIntrinsicTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

class WMFWelcomeLanguageTableViewController: UIViewController, WMFPreferredLanguagesViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private var theme = Theme.standard
    
    @IBOutlet private var languageTableView:WMFWelcomeLanguageIntrinsicTableView!
    @IBOutlet private var moreLanguagesButton:UIButton!
    @IBOutlet private var languagesDescriptionLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        languagesDescriptionLabel.text = WMFLocalizedString("welcome-languages-description", value:"We've found the following languages on your device:", comment:"Title label describing detected languages")
        
        languageTableView.alwaysBounceVertical = false
        moreLanguagesButton.setTitle(WMFLocalizedString("welcome-languages-add-or-edit-button", value:"Add or edit preferred languages", comment:"Title for button for managing languages"), for: .normal)
        moreLanguagesButton.setTitleColor(theme.colors.link, for: .normal)
        languageTableView.rowHeight = UITableView.automaticDimension
        languageTableView.estimatedRowHeight = 30
        languageTableView.register(WMFLanguageCell.wmf_classNib(), forCellReuseIdentifier: WMFLanguageCell.wmf_nibName())
        view.wmf_configureSubviewsForDynamicType()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.wmf.wmf_setShowSearchLanguageBar(MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MWKLanguageLinkController.sharedInstance().preferredLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFLanguageCell.wmf_nibName(), for: indexPath) as! WMFLanguageCell
        cell.collapseSideSpacing()
        let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[indexPath.row]
        cell.languageName = langLink.name
        cell.isPrimary = indexPath.row == 0
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // https://stackoverflow.com/a/3991688/135557
        cell.backgroundColor = .clear
        cell.backgroundView?.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
    
    @IBAction func addLanguages(withSender sender: AnyObject) {
        let langsVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        langsVC?.showExploreFeedCustomizationSettings = false
        langsVC?.delegate = self
        let navC = WMFThemeableNavigationController(rootViewController: langsVC!, theme: Theme.standard)
        present(navC, animated: true, completion: nil)
    }
    
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages:[MWKLanguageLink]){
        languageTableView.reloadData()
        languageTableView.layoutIfNeeded() // Needed for the content offset reset below to work
        languageTableView.contentOffset = .zero
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        moreLanguagesButton.titleLabel?.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
    }
}
