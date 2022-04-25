import UIKit

final class NotificationsCenterDetailView: SetupView {

    // MARK: - Properties

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(NotificationsCenterDetailHeaderCell.self, forCellReuseIdentifier: NotificationsCenterDetailHeaderCell.reuseIdentifier)
        tableView.register(NotificationsCenterDetailContentCell.self, forCellReuseIdentifier: NotificationsCenterDetailContentCell.reuseIdentifier)
        tableView.register(NotificationsCenterDetailActionCell.self, forCellReuseIdentifier: NotificationsCenterDetailActionCell.reuseIdentifier)

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        
        return tableView
    }()

    // MARK: - SetupView

    override func setup() {
        tableView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}

// MARK: - Themeable

extension NotificationsCenterDetailView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.baseBackground
        tableView.backgroundColor = theme.colors.baseBackground

        tableView.reloadData()
    }

}
