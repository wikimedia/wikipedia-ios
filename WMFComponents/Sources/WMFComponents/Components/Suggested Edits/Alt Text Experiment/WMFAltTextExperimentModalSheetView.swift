import UIKit

final class WMFAltTextExperimentModalSheetView: WMFComponentView {

    // MARK: Properties

    weak var viewModel: WMFAltTextExperimentModalSheetViewModel?
    weak var delegate: WMFAltTextExperimentModalSheetDelegate?
    weak var loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.alignment = .fill
        stackView.spacing = padding
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var headerStackView:  UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var imageFileNameStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.axis = .horizontal
        stackView.alignment = .top
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
        imageView.layer.cornerRadius = 10
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedImage))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        return imageView
    }()
    
    private lazy var imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var fileNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedFileName))
        label.addGestureRecognizer(tapGestureRecognizer)
        return label
    }()
    
    private lazy var infoLabelCharacterCounterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 12
        return stackView
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var characterCounterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.numberOfLines = 1
        return label
    }()

    private(set) lazy var textView: UITextView = {
        let textView = UIPastelessTextView(frame: .zero)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.cornerRadius = 10
        textView.returnKeyType = .done
        textView.textContainer.lineFragmentPadding = 10
        return textView
    }()

    private lazy var placeholder: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var guidanceStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = 5
        stackView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedGuidance))
        stackView.addGestureRecognizer(tapGestureRecognizer)
        return stackView
    }()
    
    private lazy var guidanceIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()
    
    private lazy var guidanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(tappedNext), for: .touchUpInside)
        return button
    }()

    private let basePadding: CGFloat = 8
    private let padding: CGFloat = 16

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: WMFAltTextExperimentModalSheetViewModel, delegate: WMFAltTextExperimentModalSheetDelegate?, loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.loggingDelegate = loggingDelegate
        super.init(frame: frame)
        textView.delegate = self
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Methods

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        configure()
    }

    func updateColors() {
        backgroundColor = theme.midBackground
        titleLabel.textColor = theme.text
        textView.backgroundColor = theme.paperBackground
        nextButton.setTitleColor(theme.link, for: .normal)
        nextButton.setTitleColor(theme.secondaryText, for: .disabled)
        placeholder.textColor = theme.secondaryText
        guidanceIconImageView.tintColor = theme.link
        guidanceLabel.textColor = theme.link
        textView.textColor = theme.text
    }

    func configure() {
        updateColors()
        updateNextButtonState()
        updatePlaceholderVisibility()

        titleLabel.text = viewModel?.localizedStrings.title
        nextButton.setTitle(viewModel?.localizedStrings.nextButton, for: .normal)
        fileNameLabel.attributedText = fileNameAttributedString()
        
        updateInfoLabelState()
        updateCharacterCounterLabelState()
        
        placeholder.text = viewModel?.localizedStrings.textViewPlaceholder
        
        textView.font = WMFFont.for(.callout, compatibleWith: traitCollection)

        if let altText = viewModel?.currentAltText {
            placeholder.isHidden = true
            textView.text = altText
        }

        titleLabel.font = WMFFont.for(.boldTitle3, compatibleWith: traitCollection)
        nextButton.titleLabel?.font = WMFFont.for(.semiboldHeadline, compatibleWith: traitCollection)
        placeholder.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        
        guidanceIconImageView.image = WMFSFSymbolIcon.for(symbol: .infoCircle, font: .callout, compatibleWith: traitCollection)
        guidanceLabel.text = viewModel?.localizedStrings.guidance
        guidanceLabel.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }

    func setup() {
        configure()

        textView.addSubview(placeholder)

        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(nextButton)
        
        imageContainerView.addSubview(imageView)
        
        imageFileNameStackView.addArrangedSubview(imageContainerView)
        imageFileNameStackView.addArrangedSubview(fileNameLabel)
        imageFileNameStackView.setCustomSpacing(12, after: imageContainerView)
        
        infoLabelCharacterCounterStackView.addArrangedSubview(infoLabel)
        infoLabelCharacterCounterStackView.addArrangedSubview(characterCounterLabel)
        
        guidanceStackView.addArrangedSubview(guidanceIconImageView)
        guidanceStackView.addArrangedSubview(guidanceLabel)

        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(imageFileNameStackView)
        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(infoLabelCharacterCounterStackView)
        stackView.addArrangedSubview(guidanceStackView)

        scrollView.addSubview(stackView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            
            imageContainerView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            imageContainerView.topAnchor.constraint(equalTo: imageView.topAnchor),
            imageContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: imageView.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: basePadding),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -padding),
            
            imageView.heightAnchor.constraint(equalToConstant: 65),
            imageView.widthAnchor.constraint(equalToConstant: 65),

            textView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 125),

            nextButton.heightAnchor.constraint(equalToConstant:44),

            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: basePadding),
            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: basePadding)
        ])
        
        guard let viewModel else {
            return
        }
        
        viewModel.populateUIImage(for: viewModel.altTextViewModel.imageFullURL) { [weak self] error in
            self?.imageView.image = self?.viewModel?.uiImage
        }

        if let currentAltText = viewModel.currentAltText {
            textView.text = currentAltText
            placeholder.isHidden = true
            updateNextButtonState()
        }
    }
    
    private func fileNameAttributedString() -> NSAttributedString? {
        
        guard let fileName = viewModel?.fileNameForDisplay else {
            return nil
        }
        
        let attributedString = NSMutableAttributedString()

        let linkAttributedString = NSMutableAttributedString(string: fileName, attributes: [.font: WMFFont.for(.boldCallout, compatibleWith: traitCollection), .foregroundColor: theme.link])

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
        
        return NSAttributedString(attributedString: attributedString)
    }
    
    private var characterCount: Int {
        return textView.text.count
    }
    
    private func updateInfoLabelState() {
        infoLabel.text = characterCount <= 125 ? viewModel?.localizedStrings.textViewBottomDescription : viewModel?.localizedStrings.characterCounterWarning
        infoLabel.textColor = characterCount <= 125 ? theme.secondaryText : theme.warning
        infoLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
    }
    
    private func updateCharacterCounterLabelState() {
        
        guard let format = viewModel?.localizedStrings.characterCounterFormat else {
            return
        }
        
        characterCounterLabel.text = String.localizedStringWithFormat(format, characterCount, 125)
        characterCounterLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        
        let oldColor = characterCounterLabel.textColor
        characterCounterLabel.textColor = characterCount <= 125 ? theme.secondaryText : theme.warning
        
        if characterCounterLabel.textColor != oldColor && characterCount > 125 {
            loggingDelegate?.didTriggerCharacterWarning()
        }
    }

    private func updateNextButtonState() {
        nextButton.isEnabled = !textView.text.isEmpty
    }

    private func updatePlaceholderVisibility() {
        placeholder.isHidden = !textView.text.isEmpty
    }
    
    @objc func tappedNext() {
        textView.resignFirstResponder()
        
        guard let altText = textView.text,
              !altText.isEmpty else {
            return
        }

        viewModel?.currentAltText = altText

        nextButton.isEnabled = false
        
        delegate?.didTapNext(altText: altText)
    }
    
    @objc func tappedImage() {
        
        guard let viewModel else {
            return
        }
        
        delegate?.didTapImage(fileName: viewModel.altTextViewModel.filename)
    }
    
    @objc func tappedFileName() {
        guard let fileName = viewModel?.altTextViewModel.filename else {
            return
        }
        
        delegate?.didTapFileName(fileName: fileName)
        loggingDelegate?.didTapFileName()
    }
    
    @objc func tappedGuidance() {
        delegate?.didTapGuidance()
    }
}

extension WMFAltTextExperimentModalSheetView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        viewModel?.currentAltText = textView.text
        updateNextButtonState()
        updatePlaceholderVisibility()
        updateInfoLabelState()
        updateCharacterCounterLabelState()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholder.isHidden = true
        loggingDelegate?.didFocusTextView()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updatePlaceholderVisibility()
    }
}

private final class UIPastelessTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
