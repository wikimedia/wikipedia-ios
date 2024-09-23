import WMFComponents

class DiffHeaderCompareView: SetupView {

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = traitCollection.horizontalSizeClass == .compact ? .vertical : .horizontal
        stackView.spacing = 16
        stackView.alignment = .top
        return stackView
    }()

    lazy var fromStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()

    lazy var toStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()

    lazy var fromHeadingLabel = {
        let label = UILabel()
        label.text = CommonStrings.diffFromHeading.localizedUppercase
        return label
    }()

    lazy var toHeadingLabel = {
        let label = UILabel()
        label.text = CommonStrings.diffToHeading.localizedLowercase
        return label
    }()

    lazy var fromTimestampLabel = {
        let label = UILabel()
        return label
    }()

    lazy var toTimestampLabel = {
        let label = UILabel()
        return label
    }()

    lazy var fromDescriptionLabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    lazy var toDescriptionLabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    lazy var userButtonMenuItems: [WMFSmallMenuButton.MenuItem] = {
        [
            WMFSmallMenuButton.Configuration.MenuItem(title: CommonStrings.userButtonContributions, image: UIImage(named: "user-contributions")),
            WMFSmallMenuButton.Configuration.MenuItem(title: CommonStrings.userButtonTalkPage, image: UIImage(systemName: "bubble.left.and.bubble.right")),
            WMFSmallMenuButton.Configuration.MenuItem(title: CommonStrings.userButtonPage, image: UIImage(systemName: "person"))
        ]
    }()

    lazy var fromMenuButton = {
        let button = WMFSmallMenuButton(configuration: WMFSmallMenuButton.Configuration(image: UIImage(systemName: "person.fill"), primaryColor: \.diffCompareAccent, menuItems: userButtonMenuItems))
        button.delegate = self
        return button
    }()

    lazy var toMenuButton = {
        let button = WMFSmallMenuButton(configuration: WMFSmallMenuButton.Configuration(image: UIImage(systemName: "person.fill"), primaryColor: \.link, menuItems: userButtonMenuItems))
        button.delegate = self
        return button
    }()

    lazy var fromMenuButtonStack = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    lazy var toMenuButtonStack = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        return stackView
    }()

    weak var delegate: DiffHeaderActionDelegate?
    private var viewModel: DiffHeaderCompareViewModel?

    override func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(fromStackView)
        stackView.addArrangedSubview(toStackView)

        fromStackView.addArrangedSubview(fromHeadingLabel)
        fromStackView.addArrangedSubview(fromTimestampLabel)
        fromStackView.addArrangedSubview(fromDescriptionLabel)
        fromStackView.addArrangedSubview(fromMenuButtonStack)
        fromMenuButtonStack.addArrangedSubview(fromMenuButton)
        fromMenuButtonStack.addArrangedSubview(FillingHorizontalSpacerView.spacerWith(minimumSpace: 10))

        toStackView.addArrangedSubview(toHeadingLabel)
        toStackView.addArrangedSubview(toTimestampLabel)
        toStackView.addArrangedSubview(toDescriptionLabel)
        toStackView.addArrangedSubview(toMenuButtonStack)
        toMenuButtonStack.addArrangedSubview(toMenuButton)
        toMenuButtonStack.addArrangedSubview(FillingHorizontalSpacerView.spacerWith(minimumSpace: 10))

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo:  layoutMarginsGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -10)
        ])

        setupStackView()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let fromConvertedPoint = self.convert(point, to: fromMenuButton)
        if fromMenuButton.point(inside: fromConvertedPoint, with: event) {
            return true
        }

        let toConvertedPoint = self.convert(point, to: toMenuButton)
        if toMenuButton.point(inside: toConvertedPoint, with: event) {
            return true
        }

        return false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupStackView()

        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()

        updateFonts(with: traitCollection)
    }

    func setupStackView() {
        if traitCollection.horizontalSizeClass == .compact {
            if smallerDevice() {
                stackView.axis = .vertical
            } else {
                stackView.axis = .horizontal
            }
        } else {
            stackView.axis = .horizontal
        }
    }

    func smallerDevice() -> Bool {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth <= 375 {
            return true
        }
        return false
    }

    func update(_ viewModel: DiffHeaderCompareViewModel) {
        self.viewModel = viewModel
        fromHeadingLabel.text = viewModel.fromModel.heading.localizedUppercase
        fromTimestampLabel.text = viewModel.fromModel.timestampString

        fromMenuButton.updateTitle(viewModel.fromModel.username)

        if viewModel.fromModel.isMinor {
            fromDescriptionLabel.attributedText = minorEditAttributedAttachment(summary: viewModel.fromModel.summary)
        } else {
            fromDescriptionLabel.text = viewModel.fromModel.summary
        }

        toHeadingLabel.text = viewModel.toModel.heading.localizedUppercase
        toTimestampLabel.text = viewModel.toModel.timestampString

        toMenuButton.updateTitle(viewModel.toModel.username)

        if viewModel.toModel.isMinor {
            toDescriptionLabel.attributedText = minorEditAttributedAttachment(summary: viewModel.toModel.summary)
        } else {
            toDescriptionLabel.text = viewModel.toModel.summary
        }

        updateFonts(with: traitCollection)
        updateAccessibilityLabels(viewModel: viewModel)
    }

    fileprivate func minorEditAttributedAttachment(summary: String?) -> NSAttributedString {
        let minorImage = UIImage(named: "minor-edit")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = minorImage
        let attributedText = NSMutableAttributedString(attachment: imageAttachment)
        attributedText.addAttributes([NSAttributedString.Key.baselineOffset: -1], range: NSRange(location: 0, length: 1))

        if let summary = summary {
            attributedText.append(NSAttributedString(string: "  \(summary)"))
            return attributedText
        } else {
            return attributedText
        }
    }

    fileprivate func updateFonts(with traitCollection: UITraitCollection) {
        toHeadingLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        fromHeadingLabel.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        toTimestampLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        fromTimestampLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        toDescriptionLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        fromDescriptionLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }

    // MARK: Accessibility labels

     func updateAccessibilityLabels(viewModel: DiffHeaderCompareViewModel) {
         let revisionAccessibilityText = WMFLocalizedString("diff-header-revision-accessibility-text", value: "Revision made at", comment: "Accessibility text to provide more context to users of assistive tecnologies about the revision date")
         

         // from stack view
         let fromIsMinorAccessibilityString = viewModel.fromModel.isMinor ? CommonStrings.minorEditTitle : ""
         let fromAuthorString = String.localizedStringWithFormat(CommonStrings.authorTitle, viewModel.fromModel.username ?? CommonStrings.unknownTitle)
         fromStackView.isAccessibilityElement = true
         fromStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [fromHeadingLabel.text, revisionAccessibilityText,fromTimestampLabel.text, fromAuthorString, fromIsMinorAccessibilityString, viewModel.fromModel.summary, CommonStrings.userMenuButtonAccesibilityText])

         // to stack view
         let toIsMinorAccessibilityString = viewModel.toModel.isMinor ? CommonStrings.minorEditTitle : ""
         let toAuthorString = String.localizedStringWithFormat(CommonStrings.authorTitle, viewModel.toModel.username ?? CommonStrings.unknownTitle)
         toStackView.isAccessibilityElement = true
         toStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [toHeadingLabel.text, revisionAccessibilityText, toTimestampLabel.text, toAuthorString, toIsMinorAccessibilityString, viewModel.toModel.summary, CommonStrings.userMenuButtonAccesibilityText])
     }

}

extension DiffHeaderCompareView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground

        fromHeadingLabel.textColor = theme.colors.secondaryText
        fromTimestampLabel.textColor = theme.colors.warning
        fromDescriptionLabel.textColor = theme.colors.primaryText

        toHeadingLabel.textColor = theme.colors.secondaryText
        toTimestampLabel.textColor = theme.colors.link
        toDescriptionLabel.textColor = theme.colors.primaryText
    }
}

extension DiffHeaderCompareView: WMFSmallMenuButtonDelegate {

    func wmfMenuButton(_ sender: WMFComponents.WMFSmallMenuButton, didTapMenuItem item: WMFComponents.WMFSmallMenuButton.MenuItem) {
        
        guard let viewModel else {
            return
        }
        
        let username: String? = sender == toMenuButton ? viewModel.toModel.username : viewModel.fromModel.username
        
        guard let username else {
            return
        }

        if item == userButtonMenuItems[0] {
            WatchlistFunnel.shared.logDiffTapUserContributions(project: viewModel.project)
            delegate?.tappedUsername(username: username, destination: .userContributions)
        } else if item == userButtonMenuItems[1] {
            WatchlistFunnel.shared.logDiffTapUserTalk(project: viewModel.project)
            delegate?.tappedUsername(username: username, destination: .userTalkPage)
        } else if item == userButtonMenuItems[2] {
            WatchlistFunnel.shared.logDiffTapUserPage(project: viewModel.project)
            delegate?.tappedUsername(username: username, destination: .userPage)
        }
    }
    
    func wmfMenuButtonDidTap(_ sender: WMFSmallMenuButton) {
        if sender == fromMenuButton {
            WatchlistFunnel.shared.logDiffTapCompareFromEditorName(project: viewModel?.project)
        } else if sender == toMenuButton {
            WatchlistFunnel.shared.logDiffTapCompareToEditorName(project: viewModel?.project)
        }
    }
}
