import UIKit

class NotificationsCenterDetailActionCell: UITableViewCell, ReusableCell {

    // MARK: - Properties

    var action: NotificationsCenterAction?
    var theme: Theme = .light

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        action = nil
    }

    func setup() {
        detailTextLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .footnote, weight: .regular, size: 13, maximumPointSize: 64)
    }

    // MARK: - Configuration

    func configure(action: NotificationsCenterAction?, theme: Theme) {
        self.theme = theme

        backgroundColor = theme.colors.paperBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground

        imageView?.tintColor = theme.colors.link
        textLabel?.textColor = theme.colors.link
        detailTextLabel?.textColor = theme.colors.secondaryText

        guard let action = action else { return }

        self.action = action

        if let actionData = action.actionData {
            let imageType = actionData.iconType
            textLabel?.text = actionData.text
            detailTextLabel?.text = actionData.destinationText
            switch imageType {
            case .custom(let name):
                imageView?.image = UIImage(named: name)
            case .system(let name):
                imageView?.image = UIImage(systemName: name)
            case .none:
                break
            }
        }
    }

}
