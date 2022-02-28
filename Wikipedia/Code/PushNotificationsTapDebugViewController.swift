
import UIKit
import WMF

@objc class PushNotificationsTapDebugViewController: SubSettingsViewController {
    
    @objc static let key = "PushNotificationsTapDebugChoice"
    
    lazy var choice: Int = {
        return UserDefaults.standard.integer(forKey: PushNotificationsTapDebugViewController.key)
    }() {
        didSet {
            UserDefaults.standard.set(choice, forKey: PushNotificationsTapDebugViewController.key)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Reuse or create a cell.
        var cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        
        guard let cell = cell else {
            fatalError()
        }

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Option 1"
            cell.detailTextLabel?.text = "Notifications Center always pushed onto stack."
            cell.imageView?.image = UIImage(systemName: "arrow.right")
        case 1:
            cell.textLabel?.text = "Option 2"
            cell.detailTextLabel?.text = "Notifications Center always presented on top."
            cell.imageView?.image = UIImage(systemName: "arrow.up")
        case 2:
            cell.textLabel?.text = "Option 3"
            cell.detailTextLabel?.text = "Presented modals dismissed, then Notifications Center pushed onto stack."
            cell.imageView?.image = UIImage(systemName: "arrowshape.turn.up.right.fill")
        case 3:
            cell.textLabel?.text = "Option 4"
            cell.detailTextLabel?.text = "Modals dismissed, stack reset to root, then Notifications Center pushed onto stack."
            cell.imageView?.image = UIImage(systemName: "arrow.clockwise.circle.fill")
        case 4:
            cell.textLabel?.text = "Option 5"
            cell.detailTextLabel?.text = "Same as option 3, with alert view confirmation in Editor."
            cell.imageView?.image = UIImage(systemName: "exclamationmark.bubble.fill")
        case 5:
            cell.textLabel?.text = "Option 6"
            cell.detailTextLabel?.text = "Same as option 4, with alert view confirmation in Editor."
            cell.imageView?.image = UIImage(systemName: "exclamationmark.arrow.circlepath")
        case 6:
            cell.textLabel?.text = "Option 7"
            cell.detailTextLabel?.text = "Same as option 4, but suppresses push entirely in Editor flow when foregrounded."
            cell.imageView?.image = UIImage(systemName: "eye.slash.fill")
        default:
            break
        }
        
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.backgroundColor = choice == indexPath.row ? UIColor.systemGray2 : UIColor.systemBackground
        
        return cell
           
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        choice = indexPath.row
        print(choice)
        tableView.reloadData()
    }

}
