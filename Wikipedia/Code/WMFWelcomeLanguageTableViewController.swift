
class WMFWelcomeLanguageTableViewController: UIViewController, WMFLanguagesViewControllerDelegate, UITableViewDataSource {
    
    @IBOutlet fileprivate var languageTableView:UITableView!
    @IBOutlet fileprivate var moreLanguagesButton:UIButton!;

    override func viewDidLoad() {
        super.viewDidLoad()
        languageTableView.isEditing = true
        languageTableView.alwaysBounceVertical = false
        moreLanguagesButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-languages-add-button"), for: UIControlState())
        moreLanguagesButton.setTitleColor(UIColor.wmf_blueTint, for: UIControlState())
        
        languageTableView.rowHeight = UITableViewAutomaticDimension
        languageTableView.estimatedRowHeight = 38
        
        self.view.wmf_configureSubviewsForDynamicType()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.wmf_userDefaults().wmf_setShowSearchLanguageBar(MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDeleteButtonsVisibility()
    }
    
    fileprivate func updateDeleteButtonsVisibility(){
        for cell in languageTableView.visibleCells as! [WMFWelcomeLanguageTableViewCell] {
            cell.deleteButton.isHidden = (MWKLanguageLinkController.sharedInstance().preferredLanguages.count == 1)
        }
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
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return (MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[indexPath.row]
            MWKLanguageLinkController.sharedInstance().removePreferredLanguage(langLink)
            tableView.deleteRows(at: [indexPath], with:.automatic)
            self.updateDeleteButtonsVisibility()
            self.useFirstPreferredLanguageAsSearchLanguage()
        }
    }
        
    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if (MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1) {
            return .delete
        } else {
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[sourceIndexPath.row]
        MWKLanguageLinkController.sharedInstance().reorderPreferredLanguage(langLink, to:destinationIndexPath.row)
        tableView.moveRow(at: sourceIndexPath, to:destinationIndexPath)
        useFirstPreferredLanguageAsSearchLanguage()
    }

    fileprivate func useFirstPreferredLanguageAsSearchLanguage() {
        guard let firstPreferredLanguage = MWKLanguageLinkController.sharedInstance().appLanguage else {
            return
        }
        UserDefaults.wmf_userDefaults().wmf_setCurrentSearchLanguageDomain(firstPreferredLanguage.siteURL())
    }

    @IBAction func addLanguages(withSender sender: AnyObject) {
        let languagesVC = WMFLanguagesViewController.nonPreferred()
        languagesVC?.delegate = self
        present(UINavigationController.init(rootViewController: languagesVC!), animated: true, completion: nil)
    }
    
    func languagesController(_ controller: WMFLanguagesViewController, didSelectLanguage language:MWKLanguageLink){
        MWKLanguageLinkController.sharedInstance().appendPreferredLanguage(language)
        self.languageTableView.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }
}
