
import Foundation
import UIKit
import WMF

class NotificationsCenterFiltersViewController: UIViewController {
    
    private var viewModel: NotificationsCenterFiltersViewModel
    private let languageLinkController: MWKLanguageLinkController
    private let didUpdateFiltersCallback: () -> Void
    
    private let tableView = UITableView.init(frame: CGRect.zero, style: .grouped)
    
    init(viewModel: NotificationsCenterFiltersViewModel, languageLinkController: MWKLanguageLinkController, didUpdateFiltersCallback: @escaping () -> Void) {
        self.viewModel = viewModel
        self.languageLinkController = languageLinkController
        self.didUpdateFiltersCallback = didUpdateFiltersCallback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Filters"
        view.backgroundColor = .white
        
        tableView.dataSource = self
        tableView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tappedDone))
    }
    
    @objc func tappedDone() {
        dismiss(animated: true)
    }
}

extension NotificationsCenterFiltersViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[safeIndex: section]?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let itemViewModel = viewModel.sections[safeIndex: indexPath.section]?.items[safeIndex: indexPath.row] else {
            return tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
        }
        
        switch itemViewModel.selectionType {
        case .checkmark:
            return checkmarkCellForItemViewModel(itemViewModel, tableView: tableView, indexPath: indexPath)
        case .toggle:
            return toggleCellForItemViewModel(itemViewModel, tableView: tableView, indexPath: indexPath)
        }
    }
    
    func checkmarkCellForItemViewModel(_ itemViewModel: NotificationsCenterFiltersViewModel.ItemViewModel, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
        cell.selectionStyle = .none
        
        cell.textLabel?.text = itemViewModel.title
        if itemViewModel.isSelected {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func toggleCellForItemViewModel(_ itemViewModel: NotificationsCenterFiltersViewModel.ItemViewModel, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier, for: indexPath) as? WMFSettingsTableViewCell,
              let notificationType = itemViewModel.type else {
            return tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)
        }
        
        cell.selectionStyle = .none
        
        cell.configure(.switch, disclosureText: nil, title: itemViewModel.title, subtitle: nil, iconName: notificationType.imageName, isSwitchOn: itemViewModel.isSelected, iconColor: .white, iconBackgroundColor: notificationType.imageBackgroundColorWithTheme(.light), controlTag: indexPath.row, theme: .light)
        cell.disclosureSwitch.isOn = itemViewModel.isSelected
        cell.disclosureSwitch.addTarget(self, action: #selector(handleNotificationTypeToggle(_:)), for: .valueChanged)
        
        return cell
    }
    
    @objc func handleNotificationTypeToggle(_ sender: UISwitch) {
        guard let itemViewModel = viewModel.sections[safeIndex: 1]?.items[safeIndex: sender.tag],
        let filterType = itemViewModel.type else {
            return
        }
        
        if sender.isOn {
            viewModel.removeFilterType(filterType, languageLinkController: languageLinkController) {
                DispatchQueue.main.async {
                    let newViewModel = NotificationsCenterFiltersViewModel(remoteNotificationsController: self.viewModel.remoteNotificationsController)
                    self.viewModel = newViewModel
                    self.didUpdateFiltersCallback()
                }
            }
        } else {
            viewModel.appendFilterType(filterType, languageLinkController: languageLinkController) {
                DispatchQueue.main.async {
                    let newViewModel = NotificationsCenterFiltersViewModel(remoteNotificationsController: self.viewModel.remoteNotificationsController)
                    self.viewModel = newViewModel
                    self.didUpdateFiltersCallback()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = viewModel.sections[safeIndex: section] else {
            return nil
        }
        
        return section.title
    }
}

extension NotificationsCenterFiltersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard indexPath.section == 0,
              let cellViewModel = viewModel.sections[safeIndex: indexPath.section]?.items[safeIndex: indexPath.row],
        let readStatus = cellViewModel.readStatus else {
            return
        }
        
        viewModel.setFilterReadStatus(newReadStatus: readStatus, languageLinkController: languageLinkController) {
            DispatchQueue.main.async {
                let newViewModel = NotificationsCenterFiltersViewModel(remoteNotificationsController: self.viewModel.remoteNotificationsController)
                self.viewModel = newViewModel
                self.tableView.reloadData()
                self.didUpdateFiltersCallback()
            }
        }
        
    }
}
