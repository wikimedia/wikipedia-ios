
import UIKit

@objc(WMFAccountViewControllerDelegate)
protocol AccountViewControllerDelegate: class {
    func accountViewControllerDidTapLogout(_ accountViewController: AccountViewController)
}

@objc(WMFAccountViewController)
class AccountViewController: SubSettingsViewController {
    
    @objc var dataStore: MWKDataStore!
    @objc weak var delegate: AccountViewControllerDelegate?
    
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = WMFAuthenticationManager.sharedInstance.loggedInUsername
        case 1:
            cell.textLabel?.text = WMFLocalizedString("account-talk-page-title", value: "Your talk page", comment: "Title for button and page letting user view their account page.")
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            showLogoutAlert()
        case 1:
            
            //todo: smart host
            if let username = WMFAuthenticationManager.sharedInstance.loggedInUsername {
                let talkPageContainerVC = TalkPageContainerViewController(name: username, host: "en.wikipedia.org", dataStore: dataStore, type: .user)
                self.navigationController?.pushViewController(talkPageContainerVC, animated: true)
            }
        default:
            break
        }
    }
    
    private func showLogoutAlert() {
        let alertController = UIAlertController(title: WMFLocalizedString("main-menu-account-logout-are-you-sure", value: "Are you sure you want to log out?", comment: "Header asking if user is sure they wish to log out."), message: nil, preferredStyle: .alert)
        let logoutAction = UIAlertAction(title: WMFLocalizedString("main-menu-account-logout", value: "Log out", comment: "Button text for logging out. The username of the user who is currently logged in is displayed after the message, e.g. Log out ExampleUserName.\n{{Identical|Log out}}"), style: .destructive) { [weak self] (action) in
            guard let self = self else {
                return
            }
            self.delegate?.accountViewControllerDidTapLogout(self)
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: WMFLocalizedString("main-menu-account-logout-cancel", value: "Cancel", comment: "Button text for hiding the log out menu.\n{{Identical|Cancel}}"), style: .cancel, handler: nil)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}


