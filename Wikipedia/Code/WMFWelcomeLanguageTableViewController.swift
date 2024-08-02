import WMFComponents

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

class WMFWelcomeLanguageTableViewController: ThemeableViewController, WMFPreferredLanguagesViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        languageTableView.reloadData()
        moreLanguagesButton.setTitleColor(theme.colors.link, for: .normal)
    }
    
    @IBOutlet private var languageTableView:WMFWelcomeLanguageIntrinsicTableView!
    @IBOutlet private var moreLanguagesButton:UIButton!
    @IBOutlet private var languagesDescriptionLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        languagesDescriptionLabel.text = WMFLocalizedString("welcome-languages-description", value:"We've found the following languages on your device:", comment:"Title label describing detected languages")
        
        languageTableView.alwaysBounceVertical = false
        moreLanguagesButton.setTitle(WMFLocalizedString("welcome-languages-add-or-edit-button", value:"Add or edit preferred languages", comment:"Title for button for managing languages"), for: .normal)
        languageTableView.rowHeight = UITableView.automaticDimension
        languageTableView.estimatedRowHeight = 30
        languageTableView.register(WMFLanguageCell.wmf_classNib(), forCellReuseIdentifier: WMFLanguageCell.wmf_nibName())
        updateFonts()
        view.wmf_configureSubviewsForDynamicType()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.wmf_setShowSearchLanguageBar(MWKDataStore.shared().languageLinkController.preferredLanguages.count > 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MWKDataStore.shared().languageLinkController.preferredLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WMFLanguageCell.wmf_nibName(), for: indexPath) as! WMFLanguageCell
        cell.collapseSideSpacing()
        let langLink = MWKDataStore.shared().languageLinkController.preferredLanguages[indexPath.row]
        cell.languageName = langLink.name
        cell.isPrimary = indexPath.row == 0
        (cell as Themeable).apply(theme: theme)
        return cell
    }
    
    @IBAction func addLanguages(withSender sender: AnyObject) {
        let langsVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        langsVC.showExploreFeedCustomizationSettings = false
        langsVC.delegate = self
        let navC = WMFThemeableNavigationController(rootViewController: langsVC, theme: self.theme)
        present(navC, animated: true, completion: nil)
    }
    
    func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages:[MWKLanguageLink]) {
        languageTableView.reloadData()
        languageTableView.layoutIfNeeded() // Needed for the content offset reset below to work
        languageTableView.contentOffset = .zero
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        moreLanguagesButton.titleLabel?.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
    }
}
