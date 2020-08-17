import UIKit

class DebugReadingListsViewController: UIViewController, UITextFieldDelegate, Themeable {

    @IBOutlet weak var listLimitTextField: UITextField!
    @IBOutlet weak var entryLimitTextField: UITextField!
    @IBOutlet weak var addEntriesSwitch: UISwitch!
    @IBOutlet weak var createListsSwitch: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var randomizeAcrossLanguagesSwitch: UISwitch!
    @IBOutlet weak var deleteAllListsSwitch: UISwitch!
    @IBOutlet weak var deleteAllEntriesSwitch: UISwitch!
    @IBOutlet weak var fullSyncSwitch: UISwitch!
    
    @IBAction func addEntriesSwitchChanged(_ sender: UISwitch) {
        if !sender.isOn {
            randomizeAcrossLanguagesSwitch.isOn = false
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let moc = MWKDataStore.shared().viewContext
        entryLimitTextField.returnKeyType = .done
        listLimitTextField.returnKeyType = .done
        entryLimitTextField.delegate = self
        listLimitTextField.delegate = self
        listLimitTextField.text = "\(moc.wmf_numberValue(forKey: "WMFCountOfListsToCreate")?.int64Value ?? 10)"
        entryLimitTextField.text = "\(moc.wmf_numberValue(forKey: "WMFCountOfEntriesToCreate")?.int64Value ?? 100)"

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(close))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    @IBAction func doit(_ sender: UIButton?) {
        let dataStore = MWKDataStore.shared()
        let readingListsController = dataStore.readingListsController
        
        let listLimit = Int64(listLimitTextField.text ?? "10") ?? 10
        let entryLimit = Int64(entryLimitTextField.text  ?? "100") ?? 100
        
        activityIndicator.startAnimating()
        sender?.isEnabled = false
        readingListsController.debugSync(createLists: createListsSwitch.isOn, listCount: listLimit, addEntries: addEntriesSwitch.isOn, randomizeLanguageEntries:randomizeAcrossLanguagesSwitch.isOn, entryCount: entryLimit, deleteLists: deleteAllListsSwitch.isOn, deleteEntries: deleteAllEntriesSwitch.isOn, doFullSync: fullSyncSwitch.isOn, completion:{
            DispatchQueue.main.async {
                sender?.isEnabled = true
                self.activityIndicator.stopAnimating()
            }
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
    }

}
