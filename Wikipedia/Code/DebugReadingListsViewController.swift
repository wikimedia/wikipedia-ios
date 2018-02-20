import UIKit

class DebugReadingListsViewController: UIViewController {

    @IBOutlet weak var listLimitTextField: UITextField!
    @IBOutlet weak var entryLimitTextField: UITextField!
    @IBOutlet weak var addEntriesSwitch: UISwitch!
    @IBOutlet weak var createListsSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let moc = SessionSingleton.sharedInstance().dataStore?.viewContext else {
            return
        }

        listLimitTextField.text = "\(moc.wmf_numberValue(forKey: "WMFCountOfListsToCreate")?.int64Value ?? 10)"
        entryLimitTextField.text = "\(moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.int64Value ?? 100)"
    }

    @IBAction func doit(_ sender: UIButton?) {
        let dataStore = SessionSingleton.sharedInstance().dataStore
        guard let readingListsController = dataStore?.readingListsController else {
            return
        }
        
        let listLimit = Int64(listLimitTextField.text ?? "10") ?? 10
        
        let entryLimit = Int64(entryLimitTextField.text  ?? "100") ?? 100
        
        activityIndicator.startAnimating()
        sender?.isEnabled = false
        readingListsController.debugSync(createLists: createListsSwitch.isOn, listCount: listLimit, addEntries: addEntriesSwitch.isOn, entryCount: entryLimit, completion:{
            sender?.isEnabled = true
            self.activityIndicator.stopAnimating()
        })
        

    }

}
