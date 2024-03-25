import UIKit

protocol WKImageRecommendationsToolbarViewDelegate: AnyObject {
    func didTapYesButton()
    func didTapNoButton()
    func didTapSkipButton()
    func goToImageCommonsPage()
}

public class WKImageRecommendationBottomSheetView: WKComponentView {

    // MARK: Properties

    private let viewModel: WKImageRecommendationBottomSheetViewModel
    internal weak var delegate: WKImageRecommendationsToolbarViewDelegate?

    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var headerStackView:  UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .gray
        return imageView
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.adjustsFontForContentSizeCategory = true
        textView.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.isSelectable = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: -10)
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        return textView
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = WKIcon.bot
        let imageView = UIImageView(image: icon)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = WKFont.for(.boldTitle3)
        return label
    }()

    private let buttonFont: UIFont = WKFont.for(.boldCallout)

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    lazy var yesToolbarButton: UIBarButtonItem = {
        let customView = UIView()

        let imageView = UIImageView(image: WKSFSymbolIcon.for(symbol: .checkmark))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = theme.link
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = viewModel.yesButtonTitle
        label.textColor = theme.link
        label.font = WKFont.for(.boldCallout)
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didPressYesButton), for: .touchUpInside)
        customView.addSubview(imageView)
        customView.addSubview(label)
        customView.addSubview(button)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: customView.centerYAnchor),

            button.topAnchor.constraint(equalTo: customView.topAnchor),
            button.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ])

        customView.layoutIfNeeded()
        let customViewWidth = label.frame.origin.x + label.frame.width
        customView.frame = CGRect(x: 0, y: 0, width: customViewWidth, height: 40)
        let barButtonItem = UIBarButtonItem(customView: customView)

        return barButtonItem
    }()

    lazy var noToolbarButton: UIBarButtonItem = {
        let customView = UIView()

        let imageView = UIImageView(image: WKSFSymbolIcon.for(symbol: .xMark))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = theme.link
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = viewModel.noButtonTitle
        label.font = WKFont.for(.boldCallout)
        label.textColor = theme.link
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didPressNoButton), for: .touchUpInside)
        customView.addSubview(imageView)
        customView.addSubview(label)
        customView.addSubview(button)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: customView.centerYAnchor),

            button.topAnchor.constraint(equalTo: customView.topAnchor),
            button.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ])

        customView.layoutIfNeeded()
        let customViewWidth = label.frame.origin.x + label.frame.width
        customView.frame = CGRect(x: 0, y: 0, width: customViewWidth, height: 40)
        let barButtonItem = UIBarButtonItem(customView: customView)

        return barButtonItem
    }()

    lazy var notSureToolbarButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(title: viewModel.notSureButtonTitle, style: .plain, target: self, action: #selector(didPressSkipButton))
        barButton.tintColor = theme.link

        let attributes: [NSAttributedString.Key: Any] = [
            .font: WKFont.for(.boldCallout),
            .foregroundColor: theme.link
        ]

        barButton.setTitleTextAttributes(attributes, for: .normal)
        return barButton
    }()

    private var regularSizeClass: Bool {
        return traitCollection.horizontalSizeClass == .regular && 
        traitCollection.horizontalSizeClass == .regular ? true : false
    }

    private var padding: CGFloat {
        return regularSizeClass ? 32 : 16
    }

    private var imageViewWidth: CGFloat {
        return regularSizeClass ? self.frame.width/2-padding : 150
    }

    private var imageViewHeight: CGFloat {
        return regularSizeClass ? UIScreen.main.bounds.height/4 : 150
    }

    private var cutoutWidth: CGFloat {
        return imageViewWidth + padding
    }

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: WKImageRecommendationBottomSheetViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        configure()
    }

    // MARK: Private Methods

    private func setup() {
        configure()

        container.addSubview(textView)
        container.addSubview(imageView)

        headerStackView.addArrangedSubview(iconImageView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.spacing = 10

        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(container)
        stackView.spacing = padding

        addSubview(stackView)
        addSubview(toolbar)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            toolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageViewWidth)
        imageWidthConstraint.priority = .required
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
        imageHeightConstraint.priority = .required

        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint
        ])

        setupTextViewExclusionPath()
        setupToolbar()
    }

    private func setupTextViewExclusionPath() {
        let height = regularSizeClass ? imageViewHeight + padding : (imageViewHeight - padding)
        let rectangleWidth: CGFloat = cutoutWidth
        let rectangleHeight: CGFloat = height

        let layoutDirection = textView.effectiveUserInterfaceLayoutDirection
        let isRTL = layoutDirection == .rightToLeft

        let rectangleOriginX: CGFloat
        if isRTL {
            let width = self.frame.width
            rectangleOriginX = width - rectangleWidth - textView.textContainerInset.right - padding * 2.5
        } else {
            rectangleOriginX = textView.textContainerInset.left
        }

        let rectangleOriginY: CGFloat = textView.textContainerInset.top

        let rectangleFrame = CGRect(x: rectangleOriginX, y: rectangleOriginY, width: rectangleWidth, height: rectangleHeight)
        let rectanglePath = UIBezierPath(rect: rectangleFrame)

        textView.textContainer.exclusionPaths = [rectanglePath]
    }

    private func updateColors() {
        backgroundColor = theme.paperBackground
        titleLabel.textColor = theme.text
        iconImageView.tintColor = theme.link
        toolbar.barTintColor = theme.midBackground
        textView.linkTextAttributes = [.foregroundColor: theme.link,
                                       .font: WKFont.for(.boldCallout)
        ]
        textView.attributedText = getTextViewAttributedString()
    }

    private func configure() {
        imageView.image = viewModel.imageThumbnail
        titleLabel.text = viewModel.headerTitle
        textView.delegate = self
        textView.attributedText = getTextViewAttributedString()
        updateColors()
    }

    private func getTextViewAttributedString() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString()

        let linkAttributedString = NSMutableAttributedString(string: viewModel.imageTitle)

        let attachment = NSTextAttachment()
        if let image = WKIcon.externalLink {
            let tintedImage = image.withTintColor(theme.link)
            attachment.image = tintedImage
        }
        let attachmentAttributedString = NSMutableAttributedString(string: " ")
        attachmentAttributedString.append(NSAttributedString(attachment: attachment))
        attachmentAttributedString.addAttributes([.foregroundColor: theme.link], range: NSRange(location: 0, length: attachmentAttributedString.length))

        let reasonAttributes = [NSAttributedString.Key.font: WKFont.for(.callout),
                                NSAttributedString.Key.foregroundColor: theme.text]
        let reasonAttributedString = NSMutableAttributedString(string: viewModel.reason, attributes: reasonAttributes)

        attributedString.append(linkAttributedString)
        attributedString.append(attachmentAttributedString)
        attributedString.append(NSAttributedString(string: "\n\n"))
        attributedString.append(reasonAttributedString)
        attributedString.append(NSAttributedString(string: "\n\n"))

        if let description = viewModel.imageDescription {
            let descriptionAttributes = [NSAttributedString.Key.font: WKFont.for(.callout),
                                         NSAttributedString.Key.foregroundColor: theme.secondaryText]
            let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
            attributedString.append(descriptionAttributedString)
        }

        if let url = URL(string: viewModel.imageLink) {
            attributedString.setAttributes([.link: url], range: NSRange(location: 0, length: linkAttributedString.length))
        }

        return attributedString
    }

    private func setupToolbar() {
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.setItems([yesToolbarButton, spacer, noToolbarButton, spacer, notSureToolbarButton], animated: true)
    }

    @objc private func didPressYesButton() {
        delegate?.didTapYesButton()
    }

    @objc private func didPressNoButton() {
        delegate?.didTapNoButton()
    }

    @objc private func didPressSkipButton() {
        delegate?.didTapSkipButton()
    }

}

extension WKImageRecommendationBottomSheetView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.goToImageCommonsPage()
        return false
    }
}

