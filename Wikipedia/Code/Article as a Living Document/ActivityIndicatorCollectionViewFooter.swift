class ActivityIndicatorCollectionViewFooter: UICollectionReusableView {
    private let loadingIndicator = UIActivityIndicatorView(style: .gray)
    private let loadingLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        loadingLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        loadingLabel.text = WMFLocalizedString("loading-indicator-text", value: "Loading", comment: "Text shown underneath loading indicator.").uppercased()

        let stackView = UIStackView(arrangedSubviews: [loadingIndicator, loadingLabel])
        stackView.axis = .vertical
        stackView.spacing = 4.0
        stackView.alignment = .center

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -30),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -30),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        loadingIndicator.startAnimating()
    }
}

extension ActivityIndicatorCollectionViewFooter: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        loadingLabel.textColor = theme.colors.secondaryText
        loadingIndicator.color = theme.colors.secondaryText
    }
}
