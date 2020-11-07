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

        addSubview(loadingLabel)
        addSubview(loadingIndicator)
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        // Need to give this a non-1000 priority to avoid constraint issues in the logs.
        let separationConstraint = loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 4)
        separationConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            loadingIndicator.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            separationConstraint,
            loadingLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -30),
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
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
