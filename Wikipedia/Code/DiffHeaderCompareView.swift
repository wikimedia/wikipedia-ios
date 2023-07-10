import UIKit
import Components

class DiffHeaderCompareView: SetupView {

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = traitCollection.horizontalSizeClass == .compact ? .vertical : .horizontal
        stackView.spacing = 16
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

    lazy var fromMenuButton = {
        // DIFFTODO: Populate with user info
        let button = WKMenuButton(configuration: .init(title: "From User 1", image: UIImage(systemName: "person.fill"), primaryColor: \.link, menuItems:
            [
                WKMenuButton.Configuration.MenuItem(title: "User page"),
                WKMenuButton.Configuration.MenuItem(title: "User talk page"),
                WKMenuButton.Configuration.MenuItem(title: "User contributions")
            ]))
        return button
    }()

    lazy var toMenuButton = {
        // DIFFTODO: Populate with user info
        let button = WKMenuButton(configuration: .init(title: "To User 2", image: UIImage(systemName: "person.fill"), primaryColor: \.diffCompareAccent, menuItems:
            [
                WKMenuButton.Configuration.MenuItem(title: "User page"),
                WKMenuButton.Configuration.MenuItem(title: "User talk page"),
                WKMenuButton.Configuration.MenuItem(title: "User contributions")
            ]))
        return button
    }()

    weak var delegate: DiffHeaderActionDelegate?

    override func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(fromStackView)
        stackView.addArrangedSubview(toStackView)

        fromStackView.addArrangedSubview(fromHeadingLabel)
        fromStackView.addArrangedSubview(fromTimestampLabel)
        fromStackView.addArrangedSubview(fromDescriptionLabel)
        fromStackView.addArrangedSubview(fromMenuButton)
        toStackView.addArrangedSubview(toHeadingLabel)
        toStackView.addArrangedSubview(toTimestampLabel)
        toStackView.addArrangedSubview(toDescriptionLabel)
        toStackView.addArrangedSubview(toMenuButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo:  layoutMarginsGuide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -10)
        ])
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

        if traitCollection.horizontalSizeClass == .compact {
            stackView.axis = .vertical
        } else {
            stackView.axis = .horizontal
        }
        stackView.setNeedsLayout()
        stackView.layoutIfNeeded()

        updateFonts(with: traitCollection)
    }

    func update(_ viewModel: DiffHeaderCompareViewModel) {
        fromHeadingLabel.text = viewModel.fromModel.heading.localizedUppercase
        fromTimestampLabel.text = viewModel.fromModel.timestampString

        if viewModel.fromModel.isMinor {
            fromDescriptionLabel.attributedText = minorEditAttributedAttachment(summary: viewModel.fromModel.summary)
        } else {
            fromDescriptionLabel.text = viewModel.fromModel.summary
        }

        toHeadingLabel.text = viewModel.toModel.heading.localizedUppercase
        toTimestampLabel.text = viewModel.toModel.timestampString

        if viewModel.toModel.isMinor {
            toDescriptionLabel.attributedText = minorEditAttributedAttachment(summary: viewModel.toModel.summary)
        } else {
            toDescriptionLabel.text = viewModel.toModel.summary
        }

        updateFonts(with: traitCollection)
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
        toHeadingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        fromHeadingLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        toTimestampLabel.font = UIFont.wmf_font(DynamicTextStyle.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        fromTimestampLabel.font = UIFont.wmf_font(DynamicTextStyle.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        toDescriptionLabel.font = UIFont.wmf_font(DynamicTextStyle.subheadline, compatibleWithTraitCollection: traitCollection)
        fromDescriptionLabel.font = UIFont.wmf_font(DynamicTextStyle.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    // DIFFTODO: Accessibility labels

//     func updateAccessibilityLabels(viewModel: DiffHeaderCompareItemViewModel) {
//         let isMinorAccessibilityString = viewModel.isMinor ? CommonStrings.minorEditTitle : ""
//         let authorString = String.localizedStringWithFormat(CommonStrings.authorTitle, viewModel.username ?? CommonStrings.unknownTitle)
//         headingAndTimestampStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [headingLabel.text, timestampLabel.text])
//         userAndSummaryStackView.accessibilityLabel = UIAccessibility.groupedAccessibilityLabel(for: [authorString, isMinorAccessibilityString, summaryLabel.text])
//     }

}

extension DiffHeaderCompareView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground

        fromHeadingLabel.textColor = theme.colors.secondaryText
        fromTimestampLabel.textColor = theme.colors.link
        fromDescriptionLabel.textColor = theme.colors.primaryText

        toHeadingLabel.textColor = theme.colors.secondaryText
        toTimestampLabel.textColor = theme.colors.warning
        toDescriptionLabel.textColor = theme.colors.primaryText
    }

}

