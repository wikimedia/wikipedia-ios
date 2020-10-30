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

        wmf_addSubview(stackView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30))
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
