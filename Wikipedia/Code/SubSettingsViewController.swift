import UIKit

class SubSettingsViewController: ViewController {
    @IBOutlet weak var tableView: UITableView!
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
