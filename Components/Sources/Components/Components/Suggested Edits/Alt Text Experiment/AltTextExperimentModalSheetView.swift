import UIKit

final class AltTextExperimentModalSheetView: WKComponentView {

    // MARK: Properties

    weak var viewModel: AltTextExperimentModalSheetViewModel?

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

    private lazy var imageAndTitleStackView:  UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.distribution = .fill
        stackView.spacing = basePadding
        stackView.alignment = .fill
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var iconImageContainerView: UIView = {
       let view = UIView()
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = WKSFSymbolIcon.for(symbol: .plusCircleFill) // temp waiting for design
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
        return label
    }()

    private lazy var textView: UITextView = {
        let textfield = UITextView(frame: .zero)
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.layer.cornerRadius = 10
        return textfield
    }()

    private lazy var placeholder: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    private let basePadding: CGFloat = 8
    private let padding: CGFloat = 16

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: AltTextExperimentModalSheetViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
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
        iconImageView.tintColor = theme.link
        nextButton.setTitleColor(theme.link, for: .normal)
        placeholder.textColor = theme.secondaryText
    }

    func configure() {
        updateColors()
        titleLabel.text = viewModel?.localizedStrings.title
        nextButton.setTitle(viewModel?.localizedStrings.buttonTitle, for: .normal)
        placeholder.text = viewModel?.localizedStrings.textViewPlaceholder
        
        titleLabel.font = WKFont.for(.boldTitle3, compatibleWith: traitCollection)
        nextButton.titleLabel?.font = WKFont.for(.semiboldHeadline, compatibleWith: traitCollection)
        placeholder.font = WKFont.for(.callout, compatibleWith: traitCollection)
    }

    func setup() {
        configure()

        textView.addSubview(placeholder)
        iconImageContainerView.addSubview(iconImageView)

        imageAndTitleStackView.addArrangedSubview(iconImageContainerView)
        imageAndTitleStackView.addArrangedSubview(titleLabel)

        headerStackView.addArrangedSubview(imageAndTitleStackView)
        headerStackView.addArrangedSubview(nextButton)

        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(textView)

        scrollView.addSubview(stackView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: basePadding),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -padding),

            textView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: 125),

            nextButton.heightAnchor.constraint(equalToConstant:44),

            placeholder.topAnchor.constraint(equalTo: textView.topAnchor, constant: basePadding),
            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: basePadding),


            iconImageContainerView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: iconImageContainerView.leadingAnchor),
            iconImageView.trailingAnchor.constraint(equalTo: iconImageContainerView.trailingAnchor),
            iconImageView.topAnchor.constraint(equalTo: iconImageContainerView.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: iconImageContainerView.bottomAnchor),
            iconImageContainerView.topAnchor.constraint(equalTo: titleLabel.topAnchor)
        ])
    }
}
