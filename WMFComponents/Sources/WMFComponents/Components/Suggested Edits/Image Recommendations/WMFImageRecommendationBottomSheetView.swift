import UIKit

protocol WMFImageRecommendationsToolbarViewDelegate: AnyObject {
    func didTapYesButton()
    func didTapNoButton()
    func didTapSkipButton()
    func goToImageCommonsPage()
    func goToGallery()
}

public class WMFImageRecommendationBottomSheetView: WMFComponentView {

    // MARK: Properties

    private let viewModel: WMFImageRecommendationBottomSheetViewModel
    internal weak var delegate: WMFImageRecommendationsToolbarViewDelegate?
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.alignment = .fill
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var headerStackView:  UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToGallery))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        return imageView
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.adjustsFontForContentSizeCategory = true
        textView.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        return textView
    }()
    
    private lazy var iconImageContainerView: UIView = {
       let view = UIView()
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = WMFIcon.bot
        let imageView = UIImageView(image: icon)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = WMFFont.for(.boldTitle3)
        return label
    }()

    private let buttonFont: UIFont = WMFFont.for(.boldCallout)

    private(set) lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    lazy var yesToolbarButton: UIBarButtonItem = {
        return customToolbarButton(image: WMFSFSymbolIcon.for(symbol: .checkmark, font: .callout), text: viewModel.yesButtonTitle, selector: #selector(didPressYesButton))
    }()

    lazy var noToolbarButton: UIBarButtonItem = {
        return customToolbarButton(image: WMFSFSymbolIcon.for(symbol: .xMark, font: .callout), text: viewModel.noButtonTitle, selector: #selector(didPressNoButton))
    }()

    lazy var notSureToolbarButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(title: viewModel.notSureButtonTitle, style: .plain, target: self, action: #selector(didPressSkipButton))
        barButton.tintColor = theme.link

        let attributes: [NSAttributedString.Key: Any] = [
            .font: WMFFont.for(.boldCallout),
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

    public init(frame: CGRect, viewModel: WMFImageRecommendationBottomSheetViewModel) {
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
    
    private func customToolbarButton(image: UIImage?, text: String, selector: Selector) -> UIBarButtonItem {
        let customView = UIView()
        customView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = WMFFont.for(.boldCallout)
        label.textColor = theme.link
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        customView.addSubview(label)

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: selector, for: .touchUpInside)
        customView.addSubview(button)
        
        NSLayoutConstraint.activate([
            
            label.trailingAnchor.constraint(equalTo: customView.trailingAnchor),
            label.topAnchor.constraint(equalTo: customView.topAnchor),
            label.bottomAnchor.constraint(equalTo: customView.bottomAnchor),
            
            button.topAnchor.constraint(equalTo: label.topAnchor),
            button.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])
        
        if let image {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = theme.link
            imageView.translatesAutoresizingMaskIntoConstraints = false
            customView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
                imageView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                imageView.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -8),
                button.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
                button.leadingAnchor.constraint(equalTo: label.leadingAnchor)
            ])
        }

        let barButtonItem = UIBarButtonItem(customView: customView)

        return barButtonItem
    }
    
    private var iconBaselineOffset: CGFloat {
        return UIFontMetrics(forTextStyle: .body).scaledValue(for: 8)
    }

    private func setup() {
        configure()

        container.addSubview(textView)
        container.addSubview(imageView)
        
        iconImageContainerView.addSubview(iconImageView)

        headerStackView.addArrangedSubview(iconImageContainerView)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.spacing = 5

        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(container)
        stackView.spacing = padding

        addSubview(scrollView)
        addSubview(toolbar)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            topAnchor.constraint(equalTo: scrollView.topAnchor),
            toolbar.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -padding),
            
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.topAnchor.constraint(equalTo: container.topAnchor),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            iconImageContainerView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: -iconBaselineOffset),
            iconImageContainerView.leadingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            iconImageContainerView.trailingAnchor.constraint(equalTo: iconImageView.trailingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
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
        let rectangleHeight = imageViewHeight + padding
        let rectangleWidth: CGFloat = cutoutWidth

        let layoutDirection = textView.effectiveUserInterfaceLayoutDirection
        let isRTL = layoutDirection == .rightToLeft

        let rectangleOriginX: CGFloat
        if isRTL {
            let width = self.frame.width
            rectangleOriginX = width - rectangleWidth - textView.textContainerInset.right - (padding * 2)
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
                                       .font: WMFFont.for(.boldCallout)
        ]
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

        let linkAttributedString = NSMutableAttributedString(string: viewModel.imageTitle, attributes: [.font: WMFFont.for(.callout), .foregroundColor: theme.link])

        let attachment = NSTextAttachment()
        if let image = WMFIcon.externalLink {
            let tintedImage = image.withTintColor(theme.link)
            attachment.image = tintedImage
        }
        let attachmentAttributedString = NSMutableAttributedString(string: " ")
        attachmentAttributedString.append(NSAttributedString(attachment: attachment))
        attachmentAttributedString.addAttributes([.foregroundColor: theme.link], range: NSRange(location: 0, length: attachmentAttributedString.length))

        attributedString.append(linkAttributedString)
        attributedString.append(attachmentAttributedString)
        
        if let url = URL(string: viewModel.imageLink) {
            attributedString.addAttributes([.link: url], range: NSRange(location: 0, length: linkAttributedString.length))
        }

        if let description = viewModel.imageDescription {
            let descriptionAttributes = [NSAttributedString.Key.font: WMFFont.for(.callout),
                                         NSAttributedString.Key.foregroundColor: theme.text]
            let descriptionAttributedString = NSMutableAttributedString(string: "\n\n" + description, attributes: descriptionAttributes)
            attributedString.append(descriptionAttributedString)
        }

        let reasonAttributes = [NSAttributedString.Key.font: WMFFont.for(.callout),
                                NSAttributedString.Key.foregroundColor: theme.secondaryText]
        let reasonAttributedString = NSMutableAttributedString(string: "\n\n" + viewModel.reason + "\n\n", attributes: reasonAttributes)
        attributedString.append(reasonAttributedString)

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
    
    @objc private func goToGallery() {
        delegate?.goToGallery()
    }

}

extension WMFImageRecommendationBottomSheetView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.goToImageCommonsPage()
        return false
    }
}

