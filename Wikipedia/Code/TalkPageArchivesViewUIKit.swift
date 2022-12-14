import Foundation
import UIKit

class TalkPageArchivesViewUIKit: SetupView {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func setup() {
        super.setup()
        
        addSubview(tableView)
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: tableView.topAnchor),
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
    }
}
