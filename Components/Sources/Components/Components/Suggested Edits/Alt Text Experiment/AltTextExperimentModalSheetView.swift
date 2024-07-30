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

    private lazy var iconImageContainerView: UIView = {
       let view = UIView()
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let icon = WKSFSymbolIcon.for(symbol: .plusCircleFill) //temp waiting for design
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
        label.font = WKFont.for(.boldTitle3)
        return label
    }()

    private lazy var textField: UITextField = {
        let textfield = UITextField(frame: .zero)
        textfield.translatesAutoresizingMaskIntoConstraints = false
//        textfield.addTarget(self, action: #selector(titleTextFieldChanged), for: .editingChanged)
        return textfield
    }()

    // MARK: Lifecycle

    public init(frame: CGRect, viewModel: AltTextExperimentModalSheetViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        setup()
    }

    let padding: CGFloat = 10

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        configure()
    }

    func updateColors() {
        backgroundColor = theme.paperBackground
        titleLabel.textColor = theme.text
        iconImageView.tintColor = theme.link
    }

    func configure() {
        updateColors()
    }

    func setup() {
        configure()

        headerStackView.addArrangedSubview(iconImageContainerView)
        headerStackView.addArrangedSubview(titleLabel)

        stackView.addSubview(textField)

        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(headerStackView)

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            topAnchor.constraint(equalTo: scrollView.topAnchor),
            bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -padding),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: padding),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -padding),
        ])

    }
}
