import UIKit

final class InsertMediaAdvancedSettingsTableViewController: UITableViewController {
    private let theme: Theme

    typealias AdvancedSettings = InsertMediaSettings.Advanced

    var advancedSettings: AdvancedSettings {
        return AdvancedSettings(wrapTextAroundImage: textWrappingSwitch.isOn, imagePosition: imagePositionSettingsTableViewController.selectedImagePosition(isTextWrappingEnabled: textWrappingSwitch.isOn), imageType: imageTypeSettingsTableViewController.selectedImageType, imageSize: imageSizeSettingsTableViewController.selectedImageSize)
    }

    struct ViewModel {
        let title: String
        let detailText: String?
        let accessoryView: UIView?
        let accessoryType: UITableViewCell.AccessoryType
        let isEnabled: Bool
        let selectionStyle: UITableViewCell.SelectionStyle
        let onSelection: (() -> Void)?

        init(title: String, detailText: String? = nil, accessoryView: UIView? = nil, accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator, isEnabled: Bool = true, selectionStyle: UITableViewCell.SelectionStyle = .default, onSelection: (() -> Void)? = nil) {
            self.title = title
            self.detailText = detailText
            self.accessoryView = accessoryView
            self.accessoryType = accessoryType
            self.isEnabled = isEnabled
            self.selectionStyle = selectionStyle
            self.onSelection = onSelection
        }
    }

    private lazy var textWrappingSwitch: UISwitch = {
        let textWrappingSwitch = UISwitch()
        textWrappingSwitch.isOn = true
        textWrappingSwitch.addTarget(self, action: #selector(toggleImagePositionEnabledState(_:)), for: .valueChanged)
        return textWrappingSwitch
    }()

    private lazy var imagePositionSettingsTableViewController = InsertMediaImagePositionSettingsTableViewController(theme: theme)
    private lazy var imageTypeSettingsTableViewController = InsertMediaImageTypeSettingsTableViewController(theme: theme)
    private lazy var imageSizeSettingsTableViewController = InsertMediaImageSizeSettingsTableViewController(theme: theme)
    
    private var viewModels: [ViewModel] {
        let textWrappingViewModel = ViewModel(title: WMFLocalizedString("insert-media-image-text-wrapping-setting", value: "Wrap text around image", comment: "Title for image setting that wraps text around image"), accessoryView: textWrappingSwitch, accessoryType: .none, selectionStyle: .none)
        let imagePositionViewModel = ViewModel(title: AdvancedSettings.ImagePosition.displayTitle, detailText: imagePositionSettingsTableViewController.selectedImagePosition(isTextWrappingEnabled: textWrappingSwitch.isOn).displayTitle, isEnabled: textWrappingSwitch.isOn) {
            self.navigationController?.pushViewController(self.imagePositionSettingsTableViewController, animated: true)
        }
        let imageTypeViewModel = ViewModel(title: AdvancedSettings.ImageType.displayTitle, detailText: imageTypeSettingsTableViewController.selectedImageType.displayTitle) {
            self.navigationController?.pushViewController(self.imageTypeSettingsTableViewController, animated: true)
        }
        let imageSizeViewModel = ViewModel(title: AdvancedSettings.ImageSize.displayTitle, detailText: imageSizeSettingsTableViewController.selectedImageSize.displayTitle) {
           self.navigationController?.pushViewController(self.imageSizeSettingsTableViewController, animated: false)
        }
        return [textWrappingViewModel, imagePositionViewModel, imageTypeViewModel, imageSizeViewModel]
    }

    init(theme: Theme) {
        self.theme = theme
        super.init(style: .plain)
    }

    @objc private func toggleImagePositionEnabledState(_ sender: UISwitch) {
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        title = "Advanced settings"
        apply(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isFirstAppearance = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        defer {
            isFirstAppearance = false
        }
        guard !isFirstAppearance else {
            return
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier) ?? UITableViewCell(style: .value1, reuseIdentifier: UITableViewCell.identifier)
        let viewModel = viewModels[indexPath.row]
        cell.textLabel?.text = viewModel.title
        cell.accessoryView = viewModel.accessoryView
        cell.accessoryType = viewModel.accessoryType
        cell.isUserInteractionEnabled = viewModel.isEnabled
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.text = viewModel.detailText
        cell.selectionStyle = cell.isUserInteractionEnabled ? viewModel.selectionStyle : .none
        apply(theme: theme, to: cell)
        return cell
    }

    private func apply(theme: Theme, to cell: UITableViewCell) {
        cell.backgroundColor = theme.colors.paperBackground
        cell.contentView.backgroundColor = theme.colors.paperBackground
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = theme.colors.midBackground
        cell.selectedBackgroundView = selectedBackgroundView
        cell.textLabel?.textColor = cell.isUserInteractionEnabled ? theme.colors.primaryText : theme.colors.secondaryText
        cell.detailTextLabel?.textColor = theme.colors.secondaryText
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel = viewModels[indexPath.row]
        viewModel.onSelection?()
    }
}

// MARK: - Themeable

extension InsertMediaAdvancedSettingsTableViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.separatorColor = theme.colors.border
    }
}
