
class WMFWelcomeLanguageTableViewController: UIViewController, WMFLanguagesViewControllerDelegate, UITableViewDataSource {
    
    @IBOutlet private var languageTableView:UITableView!
    @IBOutlet private var moreLanguagesButton:UIButton!;

    override func viewDidLoad() {
        super.viewDidLoad()
        languageTableView.editing = true
        languageTableView.alwaysBounceVertical = false
        moreLanguagesButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-languages-add-button"), forState: .Normal)
        moreLanguagesButton.setTitleColor(UIColor.wmf_blueTintColor(), forState: .Normal)
        
        languageTableView.rowHeight = UITableViewAutomaticDimension
        languageTableView.estimatedRowHeight = 38
        
        self.view.wmf_configureSubviewsForDynamicType()

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSUserDefaults.wmf_userDefaults().wmf_setShowSearchLanguageBar(MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateDeleteButtonsVisibility()
    }
    
    private func updateDeleteButtonsVisibility(){
        for cell in languageTableView.visibleCells as! [WMFWelcomeLanguageTableViewCell] {
            cell.deleteButton.hidden = (MWKLanguageLinkController.sharedInstance().preferredLanguages.count == 1)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MWKLanguageLinkController.sharedInstance().preferredLanguages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(WMFWelcomeLanguageTableViewCell.wmf_nibName(), forIndexPath: indexPath) as! WMFWelcomeLanguageTableViewCell
        let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[indexPath.row]
        cell.languageName = langLink.name
        return cell
        
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return (MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[indexPath.row]
            MWKLanguageLinkController.sharedInstance().removePreferredLanguage(langLink)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
            self.updateDeleteButtonsVisibility()
            self.useFirstPreferredLanguageAsSearchLanguage()
        }
    }
        
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (MWKLanguageLinkController.sharedInstance().preferredLanguages.count > 1) {
            return .Delete
        } else {
            return .None
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let langLink = MWKLanguageLinkController.sharedInstance().preferredLanguages[sourceIndexPath.row]
        MWKLanguageLinkController.sharedInstance().reorderPreferredLanguage(langLink, toIndex:destinationIndexPath.row)
        tableView.moveRowAtIndexPath(sourceIndexPath, toIndexPath:destinationIndexPath)
        useFirstPreferredLanguageAsSearchLanguage()
    }

    private func useFirstPreferredLanguageAsSearchLanguage() {
        let firstPreferredLanguage = MWKLanguageLinkController.sharedInstance().appLanguage
        NSUserDefaults.wmf_userDefaults().wmf_setCurrentSearchLanguageDomain(firstPreferredLanguage.siteURL())
    }

    @IBAction func addLanguages(withSender sender: AnyObject) {
        let languagesVC = WMFLanguagesViewController.nonPreferredLanguagesViewController()
        languagesVC.delegate = self
        presentViewController(UINavigationController.init(rootViewController: languagesVC), animated: true, completion: nil)
    }
    
    func languagesController(controller: WMFLanguagesViewController, didSelectLanguage language:MWKLanguageLink){
        MWKLanguageLinkController.sharedInstance().appendPreferredLanguage(language)
        self.languageTableView.reloadData()
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
