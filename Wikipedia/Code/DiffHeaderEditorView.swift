import WMFComponents

class DiffHeaderEditorView: SetupView {
    
    private lazy var containerVerticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    private lazy var containerHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 7
        return stackView
    }()
    
    private lazy var editorInfoHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
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
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var numberOfEditsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var userIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()

    private var tapGestureRecognizer: UITapGestureRecognizer?
    var tappedHeaderUsernameAction: ((Username, DiffHeaderUsernameDestination) -> Void)?
    
    private var viewModel: DiffHeaderEditorViewModel?
    
    override func setup() {
        super.setup()
        
        editorInfoHorizontalStackView.addArrangedSubview(userIconImageView)
        editorInfoHorizontalStackView.addArrangedSubview(usernameLabel)
        
        containerHorizontalStackView.addArrangedSubview(editorInfoHorizontalStackView)
        containerHorizontalStackView.addArrangedSubview(numberOfEditsLabel)
        
        containerVerticalStackView.addArrangedSubview(headingLabel)
        containerVerticalStackView.addArrangedSubview(containerHorizontalStackView)
        
        addSubview(containerVerticalStackView)
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: containerVerticalStackView.leadingAnchor, constant: -15),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: containerVerticalStackView.trailingAnchor, constant: 15),
            topAnchor.constraint(equalTo: containerVerticalStackView.topAnchor, constant: -18),
            bottomAnchor.constraint(equalTo: containerVerticalStackView.bottomAnchor, constant: 18)
        ])
        
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        numberOfEditsLabel.textAlignment = isRTL ? .left : .right
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedUserWithSender(_:)))
        
        if let tapGestureRecognizer = tapGestureRecognizer {
            editorInfoHorizontalStackView.addGestureRecognizer(tapGestureRecognizer)
        }
        editorInfoHorizontalStackView.accessibilityTraits = [.link]
    }
    
    func update(_ viewModel: DiffHeaderEditorViewModel) {
        
        self.viewModel = viewModel
        
        headingLabel.text = viewModel.heading
        usernameLabel.text = viewModel.username
        userIconImageView.image = viewModel.isTemp ? WMFIcon.temp : UIImage(named: "user-edit")
        
        if let numberOfEditsForDisplay = viewModel.numberOfEditsForDisplay,
        !numberOfEditsForDisplay.isEmpty {
            numberOfEditsLabel.text = numberOfEditsForDisplay
            numberOfEditsLabel.isHidden = false
        } else {
            numberOfEditsLabel.isHidden =  true
        }
        
        updateFonts(with: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
    
    @objc func tappedUserWithSender(_ sender: UITapGestureRecognizer) {
        if let viewModel,
           let username = viewModel.username {
            WatchlistFunnel.shared.logDiffTapSingleEditorName(project: viewModel.project)
            tappedHeaderUsernameAction?(username, .userPage)
        }
    }
}

private extension DiffHeaderEditorView {
    
    func updateFonts(with traitCollection: UITraitCollection) {
    
        headingLabel.font = WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
        usernameLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        numberOfEditsLabel.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }
}

extension DiffHeaderEditorView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        usernameLabel.textColor = theme.colors.link
        userIconImageView.tintColor = theme.colors.link
        numberOfEditsLabel.textColor = theme.colors.secondaryText
    }
}
