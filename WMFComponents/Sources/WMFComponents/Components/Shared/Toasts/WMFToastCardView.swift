import UIKit

/// A UIKit view that shows the content of one toast.
///
/// The presenter adds this view to a window and animates it. The view is not a
/// hosting controller. It does not take part in keyboard avoidance or in the
/// focus system, so it cannot start a layout loop when the keyboard appears.
final class WMFToastCardView: UIView {

    // MARK: - Nested Types

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 18
        static let contentSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 6
        static let symbolPointSize: CGFloat = 28
        static let symbolSize: CGFloat = 30
        static let thumbnailSize: CGFloat = 45
        static let thumbnailCornerRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 8)
        static let shadowRadius: CGFloat = 16
    }

    // MARK: - Properties

    private(set) var config: WMFToastConfig

    /// The presenter sets this closure. The card calls it after the button action.
    var dismiss: (() -> Void)?

    private let backgroundView: UIView
    private let contentContainer: UIView
    private let contentStack = UIStackView()
    private let textStack = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)

    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

    private var theme: WMFTheme { WMFAppEnvironment.current.theme }

    // MARK: - Lifecycle

    init(config: WMFToastConfig) {
        self.config = config

        if #available(iOS 26.0, *) {
            let effectView = UIVisualEffectView(effect: nil)
            backgroundView = effectView
            contentContainer = effectView.contentView
        } else {
            backgroundView = UIView()
            contentContainer = backgroundView
        }

        super.init(frame: .zero)
        setupViews()
        configure(with: config)
        applyTheme()

        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (view: Self, _) in
            view.applyFonts()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported. Use init(config:).")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowPath()
    }

    // MARK: - Public API

    /// Replaces the content of the card. The card keeps its position on screen.
    func configure(with config: WMFToastConfig) {
        self.config = config

        titleLabel.text = config.title

        subtitleLabel.text = config.subtitle
        subtitleLabel.isHidden = config.subtitle == nil

        button.setTitle(config.buttonTitle, for: .normal)
        button.isHidden = config.buttonTitle == nil

        textStack.spacing = (config.subtitle == nil && config.buttonTitle == nil) ? 0 : Layout.textSpacing

        configureIcon(config.icon, style: config.iconStyle)
        applyTheme()
        setNeedsLayout()
    }

    /// Reads the current theme and updates all colors.
    func applyTheme() {
        titleLabel.textColor = theme.text
        subtitleLabel.textColor = theme.secondaryText
        button.setTitleColor(theme.link, for: .normal)
        iconImageView.tintColor = theme.secondaryText

        if #available(iOS 26.0, *), let effectView = backgroundView as? UIVisualEffectView {
            let glass = UIGlassEffect()
            glass.tintColor = theme.paperBackground.withAlphaComponent(0.85)
            glass.isInteractive = true
            effectView.effect = glass
        } else {
            backgroundView.backgroundColor = theme.paperBackground
            layer.shadowColor = theme.toastShadow.cgColor
        }
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = Layout.cornerRadius
        backgroundView.layer.cornerCurve = .circular
        backgroundView.clipsToBounds = true
        addSubview(backgroundView)

        if #unavailable(iOS 26.0) {
            layer.shadowOffset = Layout.shadowOffset
            layer.shadowRadius = Layout.shadowRadius
            layer.shadowOpacity = 1
        }

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.isAccessibilityElement = false
        let iconWidth = iconImageView.widthAnchor.constraint(equalToConstant: Layout.symbolSize)
        let iconHeight = iconImageView.heightAnchor.constraint(equalToConstant: Layout.symbolSize)
        iconWidthConstraint = iconWidth
        iconHeightConstraint = iconHeight
        NSLayoutConstraint.activate([iconWidth, iconHeight])

        titleLabel.numberOfLines = 3
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 2
        subtitleLabel.adjustsFontForContentSizeCategory = true

        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = Layout.textSpacing
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        textStack.addArrangedSubview(button)

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = Layout.contentSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(textStack)
        contentContainer.addSubview(contentStack)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: Layout.verticalPadding),
            contentStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -Layout.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -Layout.verticalPadding)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCard))
        tap.cancelsTouchesInView = false
        addGestureRecognizer(tap)

        applyFonts()
    }

    private func applyFonts() {
        titleLabel.font = WMFFont.for(.subheadline)
        subtitleLabel.font = WMFFont.for(.footnote)
        button.titleLabel?.font = WMFFont.for(.boldSubheadline)
    }

    private func configureIcon(_ icon: UIImage?, style: WMFToastConfig.IconStyle) {
        guard let icon else {
            iconImageView.image = nil
            iconImageView.isHidden = true
            return
        }

        iconImageView.isHidden = false

        switch style {
        case .symbol:
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: Layout.symbolPointSize, weight: .semibold)
            iconImageView.image = icon.withConfiguration(symbolConfiguration).withRenderingMode(.alwaysTemplate)
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.layer.cornerRadius = 0
            iconImageView.clipsToBounds = false
            iconWidthConstraint?.constant = Layout.symbolSize
            iconHeightConstraint?.constant = Layout.symbolSize
        case .thumbnail:
            iconImageView.image = icon.withRenderingMode(.alwaysOriginal)
            iconImageView.contentMode = .scaleAspectFill
            iconImageView.layer.cornerRadius = Layout.thumbnailCornerRadius
            iconImageView.clipsToBounds = true
            iconWidthConstraint?.constant = Layout.thumbnailSize
            iconHeightConstraint?.constant = Layout.thumbnailSize
        }
    }

    // MARK: - Shadow

    /// Gives Core Animation the shape of the shadow. Without a path, Core Animation
    /// computes the shadow from the layer contents on every animated frame.
    private func updateShadowPath() {
        guard #unavailable(iOS 26.0) else { return }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: Layout.cornerRadius).cgPath
    }

    // MARK: - Actions

    @objc private func didTapCard(_ gesture: UITapGestureRecognizer) {
        // The button has its own action. Ignore taps that land on it.
        if !button.isHidden, button.bounds.contains(gesture.location(in: button)) {
            return
        }
        config.tapAction?()
    }

    @objc private func didTapButton() {
        config.buttonAction?()
        dismiss?()
    }
}
