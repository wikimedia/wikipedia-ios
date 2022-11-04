import UIKit
import WMF
import CocoaLumberjackSwift

final class TalkPageHeaderView: SetupView {

    // MARK: - UI Elements

    lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = [.header]
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 4
        label.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = [.header]
        return label
    }()

    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 3
        label.font = UIFont.wmf_font(.footnote)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.masksToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 4
        return imageView
    }()

    lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 12
        return stackView
    }()

    let horizontalContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.distribution = .fill
        stackView.alignment = .top
        return stackView
    }()

    lazy var bottomSpacer: VerticalSpacerView = {
        let spacer = VerticalSpacerView.spacerWith(space: 2)
        spacer.translatesAutoresizingMaskIntoConstraints = false
        return spacer
    }()

    lazy var secondaryVerticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.distribution = .fill
        stackView.alignment = .top
        return stackView
    }()

    lazy var projectSourceContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isAccessibilityElement = false
        return view
    }()

    lazy var projectImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return imageView
    }()

    lazy var projectLanguageLabelContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 2
        view.layer.borderWidth = 1
        view.isAccessibilityElement = false
        return view
    }()

    lazy var projectLanguageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.baselineAdjustment = .alignCenters
        label.font = UIFont.wmf_font(.mediumCaption2)
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        return label
    }()

    lazy var coffeeRollSpacer: VerticalSpacerView = {
        let view = VerticalSpacerView.spacerWith(space: 5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var coffeeRollContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var coffeeRollSeparator: VerticalSpacerView = {
        let view = VerticalSpacerView.spacerWith(space: 0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var coffeeRollLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        label.font = UIFont.wmf_font(.body)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var coffeeRollReadMoreButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .trailing
        button.titleLabel?.font = UIFont.wmf_scaledSystemFont(forTextStyle: .body, weight: .medium, size: 15)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    // MARK: - Lifecycle

    override func setup() {
        // Primary data
        addSubview(verticalStackView)
        horizontalContainer.addSubview(horizontalStackView)

        verticalStackView.addArrangedSubview(horizontalContainer)
        horizontalStackView.addArrangedSubview(secondaryVerticalStackView)

        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),

            horizontalContainer.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor),
            horizontalContainer.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor),

            horizontalStackView.leadingAnchor.constraint(equalTo: horizontalContainer.readableContentGuide.leadingAnchor, constant: 8),
            horizontalStackView.trailingAnchor.constraint(equalTo: horizontalContainer.readableContentGuide.trailingAnchor, constant: -8),
            horizontalStackView.topAnchor.constraint(equalTo: horizontalContainer.topAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: horizontalContainer.bottomAnchor)
        ])

        secondaryVerticalStackView.addArrangedSubview(typeLabel)
        secondaryVerticalStackView.addArrangedSubview(titleLabel)
        secondaryVerticalStackView.addArrangedSubview(descriptionLabel)

        // Article image, if available

        horizontalStackView.addArrangedSubview(imageView)

        let leadImageSideLength = CGFloat(TalkPageViewModel.leadImageSideLength)
        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: leadImageSideLength)
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: leadImageSideLength)
        imageWidthConstraint.priority = .required
        imageHeightConstraint.priority = .required

        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint
        ])

        // User talk page source

        projectSourceContainer.addSubview(projectImageView)
        projectSourceContainer.addSubview(projectLanguageLabelContainer)
        projectLanguageLabelContainer.addSubview(projectLanguageLabel)

        NSLayoutConstraint.activate([
            projectLanguageLabelContainer.leadingAnchor.constraint(equalTo: projectLanguageLabel.leadingAnchor, constant: -3),
            projectLanguageLabelContainer.trailingAnchor.constraint(equalTo: projectLanguageLabel.trailingAnchor, constant: 3),
            projectLanguageLabelContainer.topAnchor.constraint(equalTo: projectLanguageLabel.topAnchor, constant: -5),
            projectLanguageLabelContainer.bottomAnchor.constraint(equalTo: projectLanguageLabel.bottomAnchor, constant: 5),

            projectImageView.heightAnchor.constraint(equalTo: projectLanguageLabelContainer.heightAnchor),

            projectImageView.leadingAnchor.constraint(equalTo: projectSourceContainer.leadingAnchor),
            projectImageView.topAnchor.constraint(equalTo: projectSourceContainer.topAnchor, constant: 2),
            projectImageView.bottomAnchor.constraint(equalTo: projectSourceContainer.bottomAnchor, constant: -2),

            projectLanguageLabelContainer.leadingAnchor.constraint(equalTo: projectImageView.trailingAnchor, constant: 8),
            projectLanguageLabelContainer.topAnchor.constraint(equalTo: projectSourceContainer.topAnchor, constant: 2),
            projectLanguageLabelContainer.bottomAnchor.constraint(equalTo: projectSourceContainer.bottomAnchor, constant: -2)
        ])

        secondaryVerticalStackView.addArrangedSubview(projectSourceContainer)

        // Coffee Roll

        verticalStackView.addArrangedSubview(coffeeRollSpacer)
        verticalStackView.addArrangedSubview(coffeeRollContainer)

        coffeeRollContainer.addSubview(coffeeRollSeparator)
        coffeeRollContainer.addSubview(coffeeRollLabel)
        coffeeRollContainer.addSubview(coffeeRollReadMoreButton)

        NSLayoutConstraint.activate([
            coffeeRollSpacer.widthAnchor.constraint(equalTo: widthAnchor),

            coffeeRollSeparator.topAnchor.constraint(equalTo: coffeeRollContainer.topAnchor),
            coffeeRollSeparator.widthAnchor.constraint(equalTo: widthAnchor),

            coffeeRollContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            coffeeRollContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            coffeeRollLabel.leadingAnchor.constraint(equalTo: coffeeRollContainer.readableContentGuide.leadingAnchor, constant: 8),
            coffeeRollLabel.trailingAnchor.constraint(equalTo: coffeeRollContainer.readableContentGuide.trailingAnchor, constant: -8),
            coffeeRollLabel.topAnchor.constraint(equalTo: coffeeRollSeparator.topAnchor, constant: 12),
            coffeeRollLabel.bottomAnchor.constraint(equalTo: coffeeRollReadMoreButton.topAnchor, constant: -4),

            coffeeRollReadMoreButton.leadingAnchor.constraint(equalTo: coffeeRollContainer.readableContentGuide.leadingAnchor, constant: 8),
            coffeeRollReadMoreButton.trailingAnchor.constraint(equalTo: coffeeRollContainer.readableContentGuide.trailingAnchor, constant: -8),
            coffeeRollReadMoreButton.bottomAnchor.constraint(equalTo: coffeeRollContainer.bottomAnchor, constant: -8)
        ])

        verticalStackView.addArrangedSubview(bottomSpacer)

        NSLayoutConstraint.activate([
            bottomSpacer.widthAnchor.constraint(equalTo: verticalStackView.widthAnchor)
        ])
    }
    
    private var viewModel: TalkPageViewModel?

    // MARK: - Overrides

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }

        let convertedPoint = convert(point, to: coffeeRollReadMoreButton)
        if coffeeRollReadMoreButton.point(inside: convertedPoint, with: event) {
            return true
        }

        return false
    }

    // MARK: - Public

    func configure(viewModel: TalkPageViewModel) {
        
        self.viewModel = viewModel
        let languageCode = viewModel.siteURL.wmf_languageCode
        
        let typeText = viewModel.pageType == .article ? CommonStrings.talkPageTitleArticleTalk(languageCode: languageCode).localizedUppercase : CommonStrings.talkPageTitleUserTalk(languageCode: languageCode).localizedUppercase
        let projectName = viewModel.project.projectName(shouldReturnCodedFormat: false)
        typeLabel.text = typeText
        typeLabel.accessibilityLabel = "\(typeText). \(projectName)."
        
        titleLabel.text = viewModel.headerTitle
        descriptionLabel.text = viewModel.headerDescription

        if viewModel.coffeeRollText != nil {
            updateCoffeeRollText()
            
            let languageCode = viewModel.siteURL.wmf_languageCode
            let title = WMFLocalizedString("talk-pages-coffee-roll-read-more", languageCode: languageCode, value: "Read more", comment: "Title of user and article talk pages button to read more of the coffee roll.")
            coffeeRollReadMoreButton.setTitle(title, for: .normal)
            
            coffeeRollContainer.isHidden = false
            bottomSpacer.isHidden = true
        } else {
            coffeeRollContainer.isHidden = true
            bottomSpacer.isHidden = false            
        }

        projectSourceContainer.isHidden = viewModel.pageType == .article

        if let projectSourceImage = viewModel.projectSourceImage {
            projectImageView.image = projectSourceImage
        } else {
            projectImageView.removeFromSuperview()
            projectLanguageLabelContainer.leadingAnchor.constraint(equalTo: projectSourceContainer.leadingAnchor).isActive = true
        }

        if let projectLanguage = viewModel.projectLanguage {
            projectLanguageLabel.text = projectLanguage.localizedUppercase
        } else {
            projectLanguageLabelContainer.isHidden = true
        }
        
        if let leadImageURL = viewModel.leadImageURL {
            imageView.wmf_setImage(with: leadImageURL, detectFaces: true, onGPU: true, failure: { (error) in
                DDLogError("Failure loading talk page header image: \(error)")
            }, success: { [weak self] in
                self?.imageView.isHidden = false
            })
        } else {
            imageView.isHidden = true
        }
        
        updateSemanticContentAttribute(viewModel.semanticContentAttribute)
    }

    func updateLabelFonts() {
        typeLabel.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        projectLanguageLabel.font = UIFont.wmf_font(.mediumCaption2, compatibleWithTraitCollection: traitCollection)
        
        updateCoffeeRollText()
    }
    
    private func updateCoffeeRollText() {
        
        guard let viewModel = viewModel,
           let coffeeRollText = viewModel.coffeeRollText else {
            return
        }
        
        let theme = viewModel.theme
        
        let coffeeRollAttributedText: NSMutableAttributedString = coffeeRollText.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true, tagMapping: ["a": "b"])
        
        coffeeRollLabel.attributedText = coffeeRollAttributedText.removingInitialNewlineCharacters()
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        self.semanticContentAttribute = semanticContentAttribute
        typeLabel.semanticContentAttribute = semanticContentAttribute
        titleLabel.semanticContentAttribute = semanticContentAttribute
        descriptionLabel.semanticContentAttribute = semanticContentAttribute
        imageView.semanticContentAttribute = semanticContentAttribute
        horizontalStackView.semanticContentAttribute = semanticContentAttribute
        horizontalContainer.semanticContentAttribute = semanticContentAttribute
        verticalStackView.semanticContentAttribute = semanticContentAttribute
        bottomSpacer.semanticContentAttribute = semanticContentAttribute
        secondaryVerticalStackView.semanticContentAttribute = semanticContentAttribute
        projectSourceContainer.semanticContentAttribute = semanticContentAttribute
        projectImageView.semanticContentAttribute = semanticContentAttribute
        projectLanguageLabelContainer.semanticContentAttribute = semanticContentAttribute
        projectLanguageLabel.semanticContentAttribute = semanticContentAttribute
        coffeeRollSpacer.semanticContentAttribute = semanticContentAttribute
        coffeeRollContainer.semanticContentAttribute = semanticContentAttribute
        coffeeRollSeparator.semanticContentAttribute = semanticContentAttribute
        coffeeRollLabel.semanticContentAttribute = semanticContentAttribute
        coffeeRollReadMoreButton.semanticContentAttribute = semanticContentAttribute
        
        typeLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        titleLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        descriptionLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        coffeeRollLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
    }
}

extension TalkPageHeaderView: Themeable {

    func apply(theme: Theme) {
        typeLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText

        projectImageView.tintColor = theme.colors.secondaryText
        projectLanguageLabel.textColor = theme.colors.secondaryText
        projectLanguageLabelContainer.layer.borderColor = theme.colors.secondaryText.cgColor

        // TODO: Replace these once new theme colors are added/refreshed in the app
        let coffeeRollContainerBackground: UIColor!
        switch theme {
        case .light:
            coffeeRollContainerBackground = UIColor.wmf_colorWithHex(0xF8F1E3)
        case .sepia:
            coffeeRollContainerBackground = UIColor.wmf_colorWithHex(0xE1DAD1)
        case .dark:
            coffeeRollContainerBackground = UIColor.wmf_colorWithHex(0x101418)
        case .black:
            coffeeRollContainerBackground = UIColor.wmf_colorWithHex(0x101418)
        default:
            coffeeRollContainerBackground = UIColor.wmf_colorWithHex(0xF8F1E3)
        }
        coffeeRollContainer.backgroundColor = coffeeRollContainerBackground

        coffeeRollSeparator.backgroundColor = theme.colors.tertiaryText
        coffeeRollReadMoreButton.setTitleColor(theme.colors.link, for: .normal)
        updateCoffeeRollText()
        
        // Need to set textView and label textAlignment in the hierarchy again, after their attributed strings are set to the correct theme.
        updateSemanticContentAttribute(semanticContentAttribute)
    }

}
