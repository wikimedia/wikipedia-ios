import UIKit

final class InsertMediaAdvancedSettingsViewController: ViewController {
    static let title = WMFLocalizedString("advanced-settings-title", value: "Advanced settings", comment: "Title for advanced settings screen")
    private let tableView = UITableView()

    typealias AdvancedSettings = InsertMediaSettings.Advanced

    var advancedSettings: AdvancedSettings {
        return AdvancedSettings(wrapTextAroundImage: textWrappingSwitch.isOn, imagePosition: imagePositionSettingsViewController.selectedImagePosition(isTextWrappingEnabled: textWrappingSwitch.isOn), imageType: imageTypeSettingsViewController.selectedImageType, imageSize: imageSizeSettingsViewController.selectedImageSize)
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

    private lazy var imagePositionSettingsViewController = InsertMediaImagePositionSettingsViewController()
    private lazy var imageTypeSettingsViewController = InsertMediaImageTypeSettingsViewController()
    private lazy var imageSizeSettingsViewController = InsertMediaImageSizeSettingsViewController()
    
    private var viewModels: [ViewModel] {
        let textWrappingViewModel = ViewModel(title: WMFLocalizedString("insert-media-image-text-wrapping-setting", value: "Wrap text around image", comment: "Title for image setting that wraps text around image"), accessoryView: textWrappingSwitch, accessoryType: .none, selectionStyle: .none)
        let imagePositionViewModel = ViewModel(title: AdvancedSettings.ImagePosition.displayTitle, detailText: imagePositionSettingsViewController.selectedImagePosition(isTextWrappingEnabled: textWrappingSwitch.isOn).displayTitle, isEnabled: textWrappingSwitch.isOn) { [weak self] in
            guard let self = self else {
                return
            }
            self.push(self.imagePositionSettingsViewController)
        }
        let imageTypeViewModel = ViewModel(title: AdvancedSettings.ImageType.displayTitle, detailText: imageTypeSettingsViewController.selectedImageType.displayTitle) { [weak self] in
            guard let self = self else {
                return
            }
            self.push(self.imageTypeSettingsViewController)
        }
        let imageSizeViewModel = ViewModel(title: AdvancedSettings.ImageSize.displayTitle, detailText: imageSizeSettingsViewController.selectedImageSize.displayTitle) { [weak self] in
            guard let self = self else {
                return
            }
            self.push(self.imageSizeSettingsViewController)
        }
        return [textWrappingViewModel, imagePositionViewModel, imageTypeViewModel, imageSizeViewModel]
    }

    private func push(_ viewController: UIViewController & Themeable) {
        viewController.apply(theme: theme)
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc private func toggleImagePositionEnabledState(_ sender: UISwitch) {
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
    }

    override func viewDidLoad() {
        scrollView = tableView
        super.viewDidLoad()
        navigationBar.isBarHidingEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        title = InsertMediaAdvancedSettingsViewController.title
        apply(theme: theme)
    }

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

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorColor = theme.colors.border
        tableView.reloadData()
    }
}

// MARK: - Table view data source

extension InsertMediaAdvancedSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
}

// MARK: - Table view delegate

extension InsertMediaAdvancedSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewModel = viewModels[indexPath.row]
        viewModel.onSelection?()
    }
}
