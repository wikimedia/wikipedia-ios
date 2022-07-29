import Foundation
import UIKit

final class TalkPageCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "TalkPageCell"

    // MARK: - UI Elements

    lazy var rootContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.0
        return view
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        contentView.addSubview(rootContainer)
        rootContainer.addSubview(stackView)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor)
        ])
    }

}

// MARK: - Themeable

extension TalkPageCell: Themeable {

    func apply(theme: Theme) {
        rootContainer.backgroundColor = theme.colors.paperBackground
        rootContainer.layer.borderColor = theme.colors.border.cgColor
    }

}
