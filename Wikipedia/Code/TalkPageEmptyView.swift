import WMFComponents

final class TalkPageEmptyView: SetupView {

    // MARK: - Nested Types

    enum LocalizedStrings {
        static let highlightDelimiter = "**"

        static let articleHeader = WMFLocalizedString("talk-pages-empty-view-header-article", value: "The conversation starts here", comment: "Text header displayed in article talk pages when no topics are available.")
        static let articleBody = WMFLocalizedString("talk-pages-empty-view-body-article", value: "Talk pages are where people discuss how to make content on Wikipedia the best that it can be. **Start by adding a new discussion topic** to connect and collaborate with a community of Wikipedians.", comment: "Text displayed in article talk pages when no topics are available. Please do not translate or remove the ** characters as these demarcate which part of the text to display in bold.")
        static let userHeader = WMFLocalizedString("talk-pages-empty-view-header-user", value: "Start a discussion with %1$@", comment: "Text header displayed in user talk pages when no topics are available. %1$@ is replaced with a username.")
        static let userBody = WMFLocalizedString("talk-pages-empty-view-body-user", value: "Talk pages are where people discuss how to make content on Wikipedia the best that it can be. Start a new discussion to connect and collaborate with %1$@. What you say here will be public for others to see.", comment: "Text displayed in user talk pages when no topics are available. %1$@ is replaced with a username.")
        static let startDiscussion = WMFLocalizedString("talk-pages-empty-view-button-user-start-discussion", value: "Start a discussion", comment: "Button text displayed in user talk pages when no topics are available.")
        static let addTopic = WMFLocalizedString("talk-pages-empty-view-button-article-add-topic", value: "Add a new topic", comment: "Button text displayed in article talk pages when no topics are available.")
    }

    // MARK: - Properties

    fileprivate var headerLabelPrimaryFont = WMFFont.for(.boldTitle1)
    fileprivate var bodyLabelPrimaryFont = WMFFont.for(.callout)
    fileprivate var bodyLabelHighlightedFont = WMFFont.for(.boldCallout)

    lazy var headerLineHeightAttribute: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = headerLabelPrimaryFont.lineHeightMultipleToMatch(lineSpacing: 1.21)
        return style
    }()

    lazy var bodyLineHeightAttribute: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = bodyLabelPrimaryFont.lineHeightMultipleToMatch(lineSpacing: 1.33)
        return style
    }()

    // MARK: - UI Elements

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "talk-pages-empty-view-image"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = headerLabelPrimaryFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = bodyLabelPrimaryFont
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 8
        button.masksToBounds = true
        button.titleLabel?.font = WMFFont.for(.boldCallout)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var imageStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()

    lazy var headerStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()
    lazy var bodyStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()

    lazy var buttonStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()

    override func setup() {
        addSubview(scrollView)

        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(VerticalSpacerView.spacerWith(space: 12))

        stackView.addArrangedSubview(imageStack)
        imageStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 64))
        imageStack.addArrangedSubview(imageView)
        imageStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 64))

        stackView.addArrangedSubview(headerStack)
        headerStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 32))
        headerStack.addArrangedSubview(headerLabel)
        headerStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 32))

        stackView.addArrangedSubview(bodyStack)
        bodyStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 32))
        bodyStack.addArrangedSubview(bodyLabel)
        bodyStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 32))


        stackView.addArrangedSubview(buttonStack)
        buttonStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 20))
        buttonStack.addArrangedSubview(actionButton)
        buttonStack.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 20))

        stackView.addArrangedSubview(VerticalSpacerView.spacerWith(space: 20))

        stackView.setCustomSpacing(8, after: imageStack)
        stackView.setCustomSpacing(12, after: headerStack)
        stackView.setCustomSpacing(16, after: bodyStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.readableContentGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.readableContentGuide.widthAnchor),

            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if scrollView.bounces {
            scrollView.flashScrollIndicators()
        }
    }

    func configure(viewModel: TalkPageViewModel) {
        switch viewModel.pageType {
        case .article:
            headerLabel.attributedText = NSMutableAttributedString(string: LocalizedStrings.articleHeader, attributes: [.paragraphStyle: headerLineHeightAttribute])

            let bodyText = LocalizedStrings.articleBody
            let components = bodyText.components(separatedBy: LocalizedStrings.highlightDelimiter)
            let sequence = components.enumerated()
            let attributedString = NSMutableAttributedString()

            bodyLabel.attributedText = sequence.reduce(into: attributedString) { string, pair in
                let isHighlighted = !pair.offset.isMultiple(of: 2)
                let font = isHighlighted ? bodyLabelHighlightedFont : bodyLabelPrimaryFont
                string.append(NSAttributedString(string: pair.element, attributes: [.font: font]))
            }

            actionButton.setTitle(LocalizedStrings.addTopic, for: .normal)
        case .user:
            headerLabel.attributedText = NSMutableAttributedString(string: String.localizedStringWithFormat(LocalizedStrings.userHeader, viewModel.headerTitle), attributes: [.paragraphStyle: headerLineHeightAttribute])
            bodyLabel.attributedText = NSMutableAttributedString(string: String.localizedStringWithFormat(LocalizedStrings.userBody, viewModel.headerTitle), attributes: [.paragraphStyle: bodyLineHeightAttribute])
            actionButton.setTitle(LocalizedStrings.startDiscussion, for: .normal)
        }
        
        let semanticContentAttribute = viewModel.semanticContentAttribute
        updateSemanticContentAttribute(semanticContentAttribute)
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        
        container.semanticContentAttribute = semanticContentAttribute
        imageView.semanticContentAttribute = semanticContentAttribute
        headerLabel.semanticContentAttribute = semanticContentAttribute
        bodyLabel.semanticContentAttribute = semanticContentAttribute
        actionButton.semanticContentAttribute = semanticContentAttribute
        stackView.semanticContentAttribute = semanticContentAttribute
        imageStack.semanticContentAttribute = semanticContentAttribute
        headerStack.semanticContentAttribute = semanticContentAttribute
        bodyStack.semanticContentAttribute = semanticContentAttribute
        buttonStack.semanticContentAttribute = semanticContentAttribute

        headerLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
        bodyLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
    }

}

extension TalkPageEmptyView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        headerLabel.textColor = theme.colors.primaryText
        bodyLabel.textColor = theme.colors.primaryText

        actionButton.backgroundColor = theme.colors.link
        actionButton.setTitleColor(theme.colors.paperBackground, for: .normal)
    }

}
