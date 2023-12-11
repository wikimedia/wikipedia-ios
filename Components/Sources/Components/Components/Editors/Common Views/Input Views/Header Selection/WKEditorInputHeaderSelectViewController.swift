import Foundation
import UIKit

class WKEditorInputHeaderSelectViewController: WKComponentViewController {

    // MARK: Nested Types
    
    enum Configuration {
        case leftTitleNav
        case standard
    }
    
    // MARK: Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.headline, compatibleWith: appEnvironment.traitCollection)
        label.text = WKSourceEditorLocalizedStrings.current.inputViewStyle
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WKSFSymbolIcon.for(symbol: .multiplyCircleFill), style: .plain, target: self, action: #selector(close(_:)))
        button.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.closeButton
        button.accessibilityLabel = WKSourceEditorLocalizedStrings.current.accessibilityLabelButtonCloseHeaderSelectInputView
        return button
    }()
    
    private weak var delegate: WKEditorInputViewDelegate?
    private let configuration: Configuration
    
    private let reuseIdentifier = String(describing: WKEditorHeaderSelectCell.self)
    private let viewModels = [WKEditorHeaderSelectViewModel(configuration: .paragraph, isSelected: false),
                              WKEditorHeaderSelectViewModel(configuration: .heading, isSelected: false),
                              WKEditorHeaderSelectViewModel(configuration: .subheading1, isSelected: false),
                              WKEditorHeaderSelectViewModel(configuration: .subheading2, isSelected: false),
                              WKEditorHeaderSelectViewModel(configuration: .subheading3, isSelected: false),
                              WKEditorHeaderSelectViewModel(configuration: .subheading4, isSelected: false)]
    
    // MARK: Lifecycle
    
    init(configuration: Configuration, delegate: WKEditorInputViewDelegate?) {
        self.configuration = configuration
        self.delegate = delegate
        super.init()
        setupNavigationBar()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.headerSelectInputView
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.topAnchor.constraint(equalTo: tableView.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
        
        tableView.register(WKEditorHeaderSelectCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        configure(selectionState: selectionState)
        tableView.reloadData()
    }
    
    // MARK: Public
    
    func configure(selectionState: WKSourceEditorSelectionState) {
        viewModels.forEach { $0.isSelected = false }
        
        let paragraphViewModel = viewModels[0]
        let headingViewModel = viewModels[1]
        let subheading1ViewModel = viewModels[2]
        let subheading2ViewModel = viewModels[3]
        let subheading3ViewModel = viewModels[4]
        let subheading4ViewModel = viewModels[5]
        
        if selectionState.isHeading {
            headingViewModel.isSelected = true
        } else if selectionState.isSubheading1 {
            subheading1ViewModel.isSelected = true
        } else if selectionState.isSubheading2 {
            subheading2ViewModel.isSelected = true
        } else if selectionState.isSubheading3 {
            subheading3ViewModel.isSelected = true
        } else if selectionState.isSubheading4 {
            subheading4ViewModel.isSelected = true
        } else {
            paragraphViewModel.isSelected = true
        }
    }
    
    // MARK: Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: Button Actions
    
    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.didTapClose()
    }
    
    // MARK: Private Helpers
    
    private func setupNavigationBar() {
        switch configuration {
        case .standard:
            break
        case .leftTitleNav:
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        }
        navigationItem.rightBarButtonItem = closeButton
    }
    
    private func updateColors() {
        view.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        tableView.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
    }
}

// MARK: UITableViewDataSource

extension WKEditorInputHeaderSelectViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if let headerCell = cell as? WKEditorHeaderSelectCell {
            let viewModel = viewModels[indexPath.row]
            switch indexPath.row {
            case 0:
                headerCell.configure(viewModel: viewModel)
            case 1:
                headerCell.configure( viewModel: viewModel)
            case 2:
                headerCell.configure(viewModel: viewModel)
            case 3:
                headerCell.configure(viewModel: viewModel)
            case 4:
                headerCell.configure(viewModel: viewModel)
            case 5:
                headerCell.configure(viewModel: viewModel)
            default:
                break
            }
            headerCell.accessibilityTraits = viewModel.isSelected ? [.button, .selected] : [.button]

        }
        
        return cell
    }
}

// MARK: UITableViewDelegate

extension WKEditorInputHeaderSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        for (index, viewModel) in viewModels.enumerated() {
            let alreadySelected = viewModel.isSelected && index == indexPath.row
            viewModel.isSelected = index == indexPath.row
            if viewModel.isSelected && !alreadySelected {
                delegate?.didTapHeading(selectedHeading: viewModel.configuration)
            }
        }
        tableView.reloadData()
    }
}
