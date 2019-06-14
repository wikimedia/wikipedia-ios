import UIKit

class SubSettingsViewController: ViewController {
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        scrollView = tableView
        super.viewDidLoad()
    }

    override var nibName: String? {
        return "SubSettingsViewController"
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
}

extension SubSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        assertionFailure("Subclassers should override")
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assertionFailure("Subclassers should override")
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assertionFailure("Subclassers should override")
        return UITableViewCell()
    }
}

extension SubSettingsViewController: UITableViewDelegate {

}
