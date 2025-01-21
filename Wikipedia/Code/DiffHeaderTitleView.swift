import WMFComponents

class DiffHeaderTitleView: SetupView {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private(set) var viewModel: DiffHeaderTitleViewModel?
    
    private var tappedHeaderTitleAction: (() -> Void)?
    
    override func setup() {
        super.setup()
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            topAnchor.constraint(equalTo: stackView.topAnchor, constant: 5),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16)
        ])
        
        stackView.addArrangedSubview(headingLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        updateFonts(with: traitCollection)
        isAccessibilityElement = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(userDidTapTitleLabel))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tapGesture)
    }
    
    fileprivate func configureAccessibilityLabel(hasSubtitle: Bool) {
        if hasSubtitle {
            accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, titleLabel.text, subtitleLabel.text])
        } else {
            accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, titleLabel.text])
        }
    }

    func update(_ viewModel: DiffHeaderTitleViewModel, tappedHeaderTitleAction: (() -> Void)?) {

        self.viewModel = viewModel
        self.tappedHeaderTitleAction = tappedHeaderTitleAction

        headingLabel.text = viewModel.heading
        titleLabel.text = viewModel.title

        if let subtitle = viewModel.subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
            configureAccessibilityLabel(hasSubtitle: true)
        } else {
            subtitleLabel.isHidden = true
            configureAccessibilityLabel(hasSubtitle: false)
        }
        updateFonts(with: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
}

private extension DiffHeaderTitleView {
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headingLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        titleLabel.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
        if let viewModel = viewModel {
            subtitleLabel.font = WMFFont.for(viewModel.subtitleTextStyle, compatibleWith: traitCollection)
        } else {
            subtitleLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        }
    }

    @objc func userDidTapTitleLabel() {
        tappedHeaderTitleAction?()
    }
}

extension DiffHeaderTitleView: Themeable {
    func apply(theme: Theme) {
        
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.link

        if let subtitleColor = viewModel?.subtitleColor {
            subtitleLabel.textColor = subtitleColor
        } else {
            subtitleLabel.textColor = theme.colors.secondaryText
        }
    }
}
