import Foundation
import UIKit

class WKEditorInputMainViewController: WKComponentViewController {
    
    // MARK: - Properties
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.headline, compatibleWith: appEnvironment.traitCollection)
        label.text = "Text formatting"
        return label
    }()
    
    private lazy var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WKIcon.close, style: .plain, target: self, action: #selector(close(_:)))
        return button
    }()
    
    private let plainReuseIdentifier = String(describing: WKEditorToolbarPlainCell.self)
    private let groupedReuseIdentifier = String(describing: WKEditorToolbarGroupedCell.self)
    private let detailReuseIdentifier = String(describing: WKEditorSelectionDetailCell.self)
    private let destructiveReuseIdentifier = String(describing: WKEditorDestructiveCell.self)
    
    weak var delegate: WKEditorInputViewDelegate?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.topAnchor.constraint(equalTo: tableView.topAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
        
        tableView.register(WKEditorToolbarPlainCell.self, forCellReuseIdentifier: plainReuseIdentifier)
        tableView.register(WKEditorToolbarGroupedCell.self, forCellReuseIdentifier: groupedReuseIdentifier)
        tableView.register(WKEditorSelectionDetailCell.self, forCellReuseIdentifier: detailReuseIdentifier)
        tableView.register(WKEditorDestructiveCell.self, forCellReuseIdentifier: destructiveReuseIdentifier)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)
        navigationItem.rightBarButtonItem = closeButton
        
        updateColors()
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Button Actions
    
    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.didTapClose()
    }
    
    // MARK: - Private Helpers
    
    private func updateColors() {
        view.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        tableView.backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        titleLabel.textColor = WKAppEnvironment.current.theme.text
    }
}

// MARK: - UITableViewDataSource

extension WKEditorInputMainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        switch indexPath.row {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: plainReuseIdentifier, for: indexPath)
            
            if let plainCell = cell as? WKEditorToolbarPlainCell {
                plainCell.delegate = delegate
            }
            
            cell.selectionStyle = .none
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: groupedReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
        case 2:
            
            cell = tableView.dequeueReusableCell(withIdentifier: detailReuseIdentifier, for: indexPath)
            
            if let detailCell = cell as? WKEditorSelectionDetailCell {
                detailCell.configure(viewModel: WKEditorSelectionDetailViewModel(typeText: "Style", selectionText: "Paragraph"))
            }
        case 3:
            cell = tableView.dequeueReusableCell(withIdentifier: destructiveReuseIdentifier, for: indexPath)
            
            if let destructiveCell = cell as? WKEditorDestructiveCell {
                destructiveCell.configure(viewModel: WKEditorDestructiveViewModel(text: "Clear formatting"))
            }
        default:
            fatalError()
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension WKEditorInputMainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        
        if indexPath.row == 2 {
            navigationItem.backButtonTitle = "Text formatting"
            let headerVC = WKEditorInputHeaderSelectViewController(configuration: .standard, delegate: delegate)
            navigationController?.pushViewController(headerVC, animated: true)
        }
    }
}
