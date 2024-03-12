import UIKit

protocol WKImageRecommendationsToolbarViewDelegate: AnyObject {

    func didTapYesButton()
    func didTapNoButton()
    func didTapSkipButton()
}

public class WKImageRecommendationBottomSheetView: WKComponentView {

    private var viewModel: WKImageRecommendationBottomSheetViewModel
    private let padding: CGFloat
    private let viewGridFraction: CGFloat
    private var cutoutWidth: CGFloat
    private var buttonHeight: CGFloat
    private let imageViewHeight: CGFloat

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
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
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
        textView.isEditable = false
        textView.isSelectable = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 0, bottom: -10, right: -10)
        textView.textContainer.lineFragmentPadding = 0
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        textView.font = WKFont.for(.body)
        return textView
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = WKIcon.bot
        icon?.withTintColor(theme.link)
        let imageView = UIImageView(image: icon)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = WKFont.for(.boldTitle1)
        return label
    }()

    private let buttonFont: UIFont = WKFont.for(.boldCallout)

    private lazy var imageLinkButton: WKButton = {
        let button = WKButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = buttonFont
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.configuration?.titlePadding = .zero
        return button
    }()

    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    lazy var yesButton: UIBarButtonItem = {
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

    lazy var noButton: UIBarButtonItem = {
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

    lazy var notSureButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(title: viewModel.notSureButtonTitle, style: .plain, target: self, action: #selector(didPressSkipButton))
        barButton.tintColor = theme.link

        let attributes: [NSAttributedString.Key: Any] = [
            .font: WKFont.for(.boldCallout),
            .foregroundColor: theme.link
        ]

        barButton.setTitleTextAttributes(attributes, for: .normal)
        return barButton
    }()

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: WKImageRecommendationBottomSheetViewModel) {
        padding = 16
        viewGridFraction = (UIScreen.main.bounds.width-padding*2)/9
        cutoutWidth = viewGridFraction*5
        buttonHeight = CGFloat()
        imageViewHeight = 168 // get better ratio
        self.viewModel = viewModel
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private Methods

    private func setup() {
        configure()
        container.addSubview(imageLinkButton)
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

        let buttonWidth = (UIScreen.main.bounds.width-cutoutWidth)-padding*2.6

        let imageTitleTextSize = (viewModel.imageTitle as NSString).boundingRect(
            with: CGSize(width: buttonWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: buttonFont],
            context: nil).size
        buttonHeight = imageTitleTextSize.height
        let guide = self.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding*2),
            imageLinkButton.topAnchor.constraint(equalTo: container.topAnchor),
            imageLinkButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageLinkButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            imageLinkButton.heightAnchor.constraint(greaterThanOrEqualToConstant: buttonHeight),
            textView.topAnchor.constraint(equalTo: imageLinkButton.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            toolbar.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            toolbar.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])

        let imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: viewGridFraction*5-padding)
        imageWidthConstraint.priority = .required
        let imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
        imageHeightConstraint.priority = .required

        NSLayoutConstraint.activate([
            imageWidthConstraint,
            imageHeightConstraint
        ])

        setupTextViewExclusionPath()
        updateColors()
        setupToolbar()
    }

    private func setupTextViewExclusionPath() {
        let rectangleWidth: CGFloat = viewGridFraction*5
        let rectangleHeight: CGFloat = imageViewHeight - buttonHeight - padding
        let rectangleOriginX: CGFloat = 0
        let rectangleOriginY: CGFloat = 0

        let adjustedRectangleX = rectangleOriginX + textView.textContainerInset.left
        let adjustedRectangleY = rectangleOriginY + textView.textContainerInset.top

        let rectangleFrame = CGRect(x: adjustedRectangleX, y: adjustedRectangleY, width: rectangleWidth, height: rectangleHeight)
        let rectanglePath = UIBezierPath(rect: rectangleFrame)

        textView.textContainer.exclusionPaths = [rectanglePath]
    }

    private func updateColors() {
        backgroundColor = theme.paperBackground
        textView.textColor = theme.secondaryText
        titleLabel.textColor = theme.text
//        iconImageView.tintColor = theme.link
        imageLinkButton.setTitleColor(theme.link, for: .normal)
        imageLinkButton.tintColor = theme.link
    }

    private func configure() {
        imageView.image = viewModel.imageThumbnail
        textView.text = viewModel.imageDescription
        titleLabel.text = viewModel.headerTitle
        imageLinkButton.setAttributedTitle(getImageLinkButtonTitle(), for: .normal)
    
    }

    private func getImageLinkButtonTitle() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString()
        if let imageAttachment = WKIcon.externalLink {
            let attachment = NSTextAttachment(image: imageAttachment)
            attachment.image?.withTintColor(theme.link)
            attributedString.append(NSAttributedString(string: viewModel.imageTitle))
            attributedString.append(NSAttributedString(string: "  "))
            attributedString.append(NSAttributedString(attachment: attachment))
        }
        return attributedString
    }

    private func setupToolbar() {
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.setItems([yesButton, spacer, noButton, spacer, notSureButton], animated: true)
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
