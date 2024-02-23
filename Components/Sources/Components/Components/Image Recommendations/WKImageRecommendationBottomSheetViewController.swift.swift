import UIKit

protocol WKBottomSheetToolbarViewDelegate: AnyObject {

    func didTapYesButton()
    func didTapNoButton()
    func didTapSkipButton()
}

public class WKImageRecommendationBottomSheetView: WKComponentView {

    private var viewModel: WKImageRecommendationBottomSheetViewModel
    private let padding: CGFloat
    private let viewGridFraction: CGFloat
    private var cutoutSize: CGFloat
    private var buttonHeight: CGFloat
    private let imageViewHeight: CGFloat

    private weak var delegate: WKBottomSheetToolbarViewDelegate?

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
        let imageView = UIImageView()
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

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: WKImageRecommendationBottomSheetViewModel) {
        padding = 16
        viewGridFraction = (UIScreen.main.bounds.width-padding*2)/9
        cutoutSize = viewGridFraction*5
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

        let buttonWidth = (UIScreen.main.bounds.width-cutoutSize)-padding*2

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
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            imageLinkButton.topAnchor.constraint(equalTo: container.topAnchor),
            imageLinkButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageLinkButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            imageLinkButton.heightAnchor.constraint(greaterThanOrEqualToConstant: buttonHeight),
            textView.topAnchor.constraint(equalTo: imageLinkButton.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
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
        iconImageView.tintColor = theme.link
        imageLinkButton.setTitleColor(theme.link, for: .normal)
        imageLinkButton.tintColor = theme.link
    }

    private func configure() {
        imageView.image = viewModel.image
        textView.text = viewModel.imageDescription
        titleLabel.text = viewModel.headerTitle
        imageLinkButton.setAttributedTitle(getButtonTitle(), for: .normal)
        iconImageView.image = viewModel.headerIcon
    }

    private func getButtonTitle() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString()
        if let imageAttachment = WKIcon.externalLink {
            let attachment = NSTextAttachment(image: imageAttachment)
            attachment.image?.withTintColor(theme.link)
            attributedString.append(NSAttributedString(string: viewModel.imageTitle))
            attributedString.append(NSAttributedString(string: " "))
            attributedString.append(NSAttributedString(attachment: attachment))
        }
        return attributedString
    }

    private func setupToolbar() {
        let yesButton = getToolbarButton(title: viewModel.yesButtonTitle, icon: WKSFSymbolIcon.for(symbol: .checkmark) ?? UIImage(), target: self, action: #selector(didPressYesButton))
        let noButton = getToolbarButton(title: viewModel.noButtonTitle, icon: WKSFSymbolIcon.for(symbol: .xMark) ?? UIImage(), target: self, action: #selector(didPressNoButton))
        let notSureButton = UIBarButtonItem(title: viewModel.notSureButtonTitle, style: .plain, target: self, action: #selector(didPressSkipButton))
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        toolbar.setItems([yesButton, spacer, noButton, spacer, notSureButton], animated: true)
    }

    private func getToolbarButton(title: String, icon: UIImage, target: Any?, action: Selector) -> UIBarButtonItem {
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.setTitle(title, for: .normal)
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = WKFont.for(.body)
        button.sizeToFit()
        button.addTarget(target, action: action, for: .touchUpInside)

        let barButtonItem = UIBarButtonItem(customView: button)
        return barButtonItem
    }

    @objc func didPressYesButton() {
        delegate?.didTapYesButton()

    }

    @objc func didPressNoButton() {
        delegate?.didTapNoButton()
    }

    @objc func didPressSkipButton() {
        delegate?.didTapSkipButton()
    }

}


