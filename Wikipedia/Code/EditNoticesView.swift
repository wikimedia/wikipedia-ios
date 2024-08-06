import WMFComponents

final class EditNoticesView: SetupView {

    // MARK: - UI Elements

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.isUserInteractionEnabled = true
        return stackView
    }()

    lazy var editNoticesImageContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editNoticesImageView)
        NSLayoutConstraint.activate([
            editNoticesImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            editNoticesImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            editNoticesImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            editNoticesImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()

    lazy var editNoticesImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 50)
        imageWidthConstraint.priority = .required
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
        imageHeightConstraint.priority = .required

        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint
        ])

        return imageView
    }()

    lazy var editNoticesTitle: UILabel = {
        let label = UILabel()
        label.text = CommonStrings.editNotices
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var editNoticesSubtitle: UILabel = {
        let label = UILabel()
        label.text =  WMFLocalizedString("edit-notices-please-read", value: "Please read before editing", comment: "Subtitle displayed in edit notices view.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var doneContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitle(CommonStrings.doneTitle, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var footerStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20
        return stackView
    }()

    lazy var footerSwitchLabel: UILabel = {
        let label = UILabel()
        label.text = WMFLocalizedString("edit-notices-always-display", value: "Always display edit notices", comment: "Title for toggle switch label in edit notices view.")
        label.numberOfLines = 0
        label.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return label
    }()

    lazy var switchContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toggleSwitch)
        NSLayoutConstraint.activate([
            toggleSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toggleSwitch.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            toggleSwitch.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            toggleSwitch.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        return view
    }()

    lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.setContentHuggingPriority(.required, for: .vertical)
        toggle.setContentCompressionResistancePriority(.required, for: .vertical)
        return toggle
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()

    // MARK: - Private Properties

    private var doneButtonTrailingConstraint: NSLayoutConstraint!

    private var doneButtonTrailingMargin: CGFloat {
        return traitCollection.verticalSizeClass == .compact ? -20 : -8
    }

    // MARK: - Override

    override func setup() {
        // Top "navigation" bar

        addSubview(doneContainer)
        doneContainer.addSubview(doneButton)
        doneButtonTrailingConstraint = doneButton.trailingAnchor.constraint(equalTo: doneContainer.readableContentGuide.trailingAnchor, constant: doneButtonTrailingMargin)

        // Primary content container, scrollable

        addSubview(contentContainer)
        contentContainer.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(editNoticesImageContainer)
        stackView.addArrangedSubview(VerticalSpacerView.spacerWith(space: 10))
        stackView.addArrangedSubview(editNoticesTitle)
        stackView.addArrangedSubview(VerticalSpacerView.spacerWith(space: 6))
        stackView.addArrangedSubview(editNoticesSubtitle)
        stackView.addArrangedSubview(VerticalSpacerView.spacerWith(space: 32))
        stackView.addArrangedSubview(textView)

        // Footer label/switch

        addSubview(footerContainer)
        footerContainer.addSubview(footerStack)

        footerStack.addArrangedSubview(footerSwitchLabel)
        footerStack.addArrangedSubview(switchContainer)

        NSLayoutConstraint.activate([
            doneContainer.topAnchor.constraint(equalTo: topAnchor),
            doneContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            doneContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            doneContainer.bottomAnchor.constraint(equalTo: contentContainer.topAnchor),

            doneButtonTrailingConstraint,
            doneButton.topAnchor.constraint(equalTo: doneContainer.topAnchor, constant: 16),
            doneButton.bottomAnchor.constraint(equalTo: doneContainer.bottomAnchor, constant: -5),

            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentContainer.readableContentGuide.leadingAnchor, constant: 24),
            scrollView.trailingAnchor.constraint(equalTo: contentContainer.readableContentGuide.trailingAnchor, constant: -24),

            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            footerContainer.topAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            footerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            footerStack.leadingAnchor.constraint(equalTo: footerContainer.readableContentGuide.leadingAnchor, constant: 20),
            footerStack.trailingAnchor.constraint(equalTo: footerContainer.readableContentGuide.trailingAnchor, constant: -20),
            footerStack.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: 16),
            footerStack.bottomAnchor.constraint(equalTo: footerContainer.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        changeTextViewVoiceOverVisibility(isVisible: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        doneButtonTrailingConstraint.constant = doneButtonTrailingMargin
        doneContainer.setNeedsLayout()
    }

    // MARK: - Public
    
    func changeTextViewVoiceOverVisibility(isVisible: Bool) {
        if !isVisible {
            accessibilityElements = [doneButton, editNoticesTitle, editNoticesSubtitle, footerSwitchLabel, toggleSwitch]
        } else {
            accessibilityElements = [doneButton, editNoticesTitle, editNoticesSubtitle, textView, footerSwitchLabel, toggleSwitch]
        }
    }

    func configure(viewModel: EditNoticesViewModel, theme: Theme) {
        let styles: HtmlUtils.Styles = HtmlUtils.Styles(font: WMFFont.for(.callout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 3)

        let attributedNoticeString = NSMutableAttributedString()
        for notice in viewModel.notices {
            let noticeString = NSAttributedString.attributedStringFromHtml(notice.description, styles: styles)
            attributedNoticeString.append(noticeString)
        }

        textView.attributedText = attributedNoticeString.removingInitialNewlineCharacters().removingRepetitiveNewlineCharacters()
        textView.textAlignment = viewModel.semanticContentAttribute == .forceRightToLeft ? .right : .left
        
        // Update colors
        backgroundColor = theme.colors.paperBackground
        doneButton.setTitleColor(theme.colors.link, for: .normal)
        editNoticesImageView.tintColor = theme.colors.primaryText
        editNoticesTitle.textColor = theme.colors.primaryText
        editNoticesSubtitle.textColor = theme.colors.primaryText
        textView.backgroundColor = theme.colors.paperBackground
        textView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        footerSwitchLabel.textColor = theme.colors.primaryText
    }

}
