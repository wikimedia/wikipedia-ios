
import UIKit

@objc(WMFAccountViewController)
class AccountViewController: SubSettingsViewController {
    
    @objc var dataStore: MWKDataStore!
    private let cellIdentifier = "TableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.account
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = WMFLocalizedString("account-talk-page-title", value: "Your talk page", comment: "Title for button and page letting user view their account page.")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let talkPageContainerVC = TalkPageContainerViewController.wmf_viewControllerFromTalkPageStoryboard()
        talkPageContainerVC.name = WMFAuthenticationManager.sharedInstance.loggedInUsername
        talkPageContainerVC.dataStore = self.dataStore
        self.navigationController?.pushViewController(talkPageContainerVC, animated: true)
    }
}


