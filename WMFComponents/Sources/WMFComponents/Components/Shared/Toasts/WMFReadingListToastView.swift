import UIKit

public final class WMFReadingListToastView: UIView {

    // MARK: - Properties

    private var config: WMFReadingListToastConfig
    private let dismissHandler: () -> Void

    private var theme: WMFTheme { WMFAppEnvironment.current.theme }

    // MARK: - Subviews

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        return button
    }()

    private let textStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .leading
        sv.spacing = 8
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    // MARK: - Init

    public init(config: WMFReadingListToastConfig, dismiss: @escaping () -> Void) {
        self.config = config
        self.dismissHandler = dismiss
        super.init(frame: .zero)
        setup()
        applyConfig(config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        layer.cornerRadius = 24
        layer.cornerCurve = .circular
        clipsToBounds = true

        titleLabel.font = WMFFont.for(.subheadline)
        actionButton.titleLabel?.font = WMFFont.for(.semiboldHeadline)
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(actionButton)

        // Spacer to push content left (mirrors SwiftUI Spacer)
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(spacer)

        addSubview(contentStack)

        let iconWidth = iconImageView.widthAnchor.constraint(equalToConstant: 30)
        let iconHeight = iconImageView.heightAnchor.constraint(equalToConstant: 30)
        iconWidthConstraint = iconWidth
        iconHeightConstraint = iconHeight
        NSLayoutConstraint.activate([iconWidth, iconHeight])

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }

    // MARK: - Configuration

    private func applyConfig(_ config: WMFReadingListToastConfig) {
        self.config = config

        backgroundColor = theme.paperBackground

        if let icon = config.icon {
            let isTemplateLike = icon.isSymbolImage || icon.renderingMode == .alwaysTemplate
            if isTemplateLike {
                iconImageView.image = icon.withRenderingMode(.alwaysTemplate)
                iconImageView.tintColor = theme.secondaryText
                iconImageView.contentMode = .scaleAspectFit
                iconImageView.layer.cornerRadius = 0
                iconImageView.clipsToBounds = false
                iconWidthConstraint?.constant = 30
                iconHeightConstraint?.constant = 30
            } else {
                iconImageView.image = icon
                iconImageView.contentMode = .scaleAspectFill
                iconImageView.layer.cornerRadius = 8
                iconImageView.clipsToBounds = true
                iconWidthConstraint?.constant = 45
                iconHeightConstraint?.constant = 45
            }
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        titleLabel.text = config.title
        titleLabel.textColor = theme.text

        if let buttonTitle = config.buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.setTitleColor(theme.link, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    public func update(with config: WMFReadingListToastConfig) {
        applyConfig(config)
    }

    // MARK: - Actions

    @objc private func viewTapped() {
        config.tapAction?()
    }

    @objc private func buttonTapped() {
        config.buttonAction?()
    }
}
