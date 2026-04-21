import WMFComponents
import WMF
import Combine
import SwiftUI
import WMFData
import WMFNativeLocalizations

final class CollectPrizeViewController: UIViewController, Themeable {
    
    // MARK: - Properties
    
    private var theme: Theme
    private static let badgeUserDefaultsKey = "collect-prize-badge-enabled"
    private let activityTabDataController = WMFActivityTabDataController.shared
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    
    private lazy var closeButtonHostingController: UIHostingController<WMFLargeCloseButton> = {
        guard let button = WMFLargeCloseButton(imageType: .plainX, action: { [weak self] in self?.closeTapped() }) else {
            fatalError("Failed to create WMFLargeCloseButton")
        }
        let hostingController = UIHostingController(rootView: button)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        return hostingController
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = CommonStrings.collectPrizeTitle
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: Badge Section
    
    private lazy var badgeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "babyGlobePrize")
        return imageView
    }()
    
    private lazy var badgeHeadlineLabel: UILabel = {
        let label = UILabel()
        label.text = WMFLocalizedString("collect-prize-badge-headline", value: "One adorable badge, earned", comment: "Headline for badge section of collect prize modal")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var badgeSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = WMFLocalizedString("collect-prize-badge-subtitle", value: "You completed the challenge and Baby Globe couldn't be prouder. Bask in your achievement with a digital badge for your activity tab.", comment: "Subtitle for badge section of collect prize modal")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var badgeToggleRow: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = WMFLocalizedString("collect-prize-badge-toggle", value: "25-day challenge badge", comment: "Toggle label for 25-day challenge badge on collect prize modal")
        label.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = activityTabDataController.readingChallengeBadgeEnabled
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(badgeToggleChanged(_:)), for: .valueChanged)
        toggle.tag = 100

        container.addSubview(separator)
        container.addSubview(label)
        container.addSubview(toggle)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: container.topAnchor),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            label.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 14),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),
            label.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),

            toggle.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])

        self.badgeToggleSeparator = separator
        self.badgeToggleLabel = label

        return container
    }()

    // Weak refs set during badgeToggleRow lazy init
    private weak var badgeToggleSeparator: UIView?
    private weak var badgeToggleLabel: UILabel?

    // MARK: Store Section

    private lazy var prizeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "reading-challenge-prize")
        return imageView
    }()
    
    private lazy var headlineLabel: UILabel = {
        let label = UILabel()
        label.text = WMFLocalizedString("collect-prize-headline", value: "Curiosity looks good on you! 🛍️", comment: "Headline for collect prize modal")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: WMFLocalizedString("collect-prize-subtitle", value: "Celebrate completing the challenge with 15%% off at the Wikipedia Store.", comment: "Subtitle for collect prize modal. Please leave %% unchanged for proper formatting."))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var primaryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(format: WMFLocalizedString("collect-prize-button-title", value: "Get 15%% off at the store", comment: "Button title for collect prize modal. Please leave %% unchanged for proper formatting."))
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(primaryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(closeButtonHostingController)
        closeButtonHostingController.didMove(toParent: self)
        setupLayout()
        apply(theme: theme)
    }
    
    private func setupLayout() {
        // Header (close button + title) stays fixed outside scroll
        view.addSubview(closeButtonHostingController.view)
        view.addSubview(titleLabel)
        view.addSubview(prizeImageView)
        view.addSubview(headlineLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(primaryButton)

        prizeImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Badge image needs a fixed height so we wrap it in a container
        let badgeImageContainer = UIView()
        badgeImageContainer.translatesAutoresizingMaskIntoConstraints = false
        badgeImageContainer.addSubview(badgeImageView)

        NSLayoutConstraint.activate([
            badgeImageView.topAnchor.constraint(equalTo: badgeImageContainer.topAnchor),
            badgeImageView.bottomAnchor.constraint(equalTo: badgeImageContainer.bottomAnchor),
            badgeImageView.centerXAnchor.constraint(equalTo: badgeImageContainer.centerXAnchor),
            badgeImageView.heightAnchor.constraint(equalToConstant: 130),
            badgeImageView.widthAnchor.constraint(equalToConstant: 110)
        ])

        // Badge text container with padding
        let badgeTextContainer = UIView()
        badgeTextContainer.translatesAutoresizingMaskIntoConstraints = false
        badgeTextContainer.addSubview(badgeHeadlineLabel)
        badgeTextContainer.addSubview(badgeSubtitleLabel)

        NSLayoutConstraint.activate([
            badgeHeadlineLabel.topAnchor.constraint(equalTo: badgeTextContainer.topAnchor),
            badgeHeadlineLabel.leadingAnchor.constraint(equalTo: badgeTextContainer.leadingAnchor, constant: 16),
            badgeHeadlineLabel.trailingAnchor.constraint(equalTo: badgeTextContainer.trailingAnchor, constant: -16),

            badgeSubtitleLabel.topAnchor.constraint(equalTo: badgeHeadlineLabel.bottomAnchor, constant: 8),
            badgeSubtitleLabel.leadingAnchor.constraint(equalTo: badgeTextContainer.leadingAnchor, constant: 32),
            badgeSubtitleLabel.trailingAnchor.constraint(equalTo: badgeTextContainer.trailingAnchor, constant: -32),
            badgeSubtitleLabel.bottomAnchor.constraint(equalTo: badgeTextContainer.bottomAnchor)
        ])

        // Store section container with padding
        let storeContainer = UIView()
        storeContainer.translatesAutoresizingMaskIntoConstraints = false
        storeContainer.addSubview(prizeImageView)
        storeContainer.addSubview(headlineLabel)
        storeContainer.addSubview(subtitleLabel)
        storeContainer.addSubview(primaryButton)

        NSLayoutConstraint.activate([
            prizeImageView.topAnchor.constraint(equalTo: storeContainer.topAnchor, constant: 24),
            prizeImageView.leadingAnchor.constraint(equalTo: storeContainer.leadingAnchor, constant: 16),
            prizeImageView.trailingAnchor.constraint(equalTo: storeContainer.trailingAnchor, constant: -16),
            prizeImageView.heightAnchor.constraint(equalToConstant: 220),

            headlineLabel.topAnchor.constraint(equalTo: prizeImageView.bottomAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: storeContainer.leadingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: storeContainer.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: storeContainer.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: storeContainer.trailingAnchor, constant: -32),

            primaryButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            primaryButton.leadingAnchor.constraint(equalTo: storeContainer.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: storeContainer.trailingAnchor, constant: -16),
            primaryButton.bottomAnchor.constraint(equalTo: storeContainer.bottomAnchor, constant: -32)
        ])

        let spacerAfterImage = spacerView(height: 8)
        let spacerAfterText = spacerView(height: 24)

        contentStackView.addArrangedSubview(badgeImageContainer)
        contentStackView.addArrangedSubview(spacerAfterImage)
        contentStackView.addArrangedSubview(badgeTextContainer)
        contentStackView.addArrangedSubview(spacerAfterText)
        contentStackView.addArrangedSubview(badgeToggleRow)
        contentStackView.addArrangedSubview(storeContainer)

        NSLayoutConstraint.activate([
            closeButtonHostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButtonHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: closeButtonHostingController.view.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButtonHostingController.view.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -56),

            prizeImageView.topAnchor.constraint(equalTo: closeButtonHostingController.view.bottomAnchor, constant: 16),
            prizeImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            prizeImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            prizeImageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            headlineLabel.topAnchor.constraint(equalTo: prizeImageView.bottomAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            primaryButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            primaryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: closeButtonHostingController.view.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func spacerView(height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func badgeToggleChanged(_ sender: UISwitch) {
        activityTabDataController.readingChallengeBadgeEnabled = sender.isOn
    }
    
    @objc private func primaryButtonTapped() {
        guard let url = URL(string: "https://store.wikimedia.org/discount/Widget15") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Themeable
    
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else { return }
        
        view.backgroundColor = theme.colors.paperBackground
        
        titleLabel.font = WMFFont.for(.semiboldHeadline)
        titleLabel.textColor = theme.colors.primaryText

        badgeHeadlineLabel.font = WMFFont.for(.boldBody)
        badgeHeadlineLabel.textColor = theme.colors.primaryText

        badgeSubtitleLabel.font = WMFFont.for(.subheadline)
        badgeSubtitleLabel.textColor = theme.colors.primaryText

        badgeToggleSeparator?.backgroundColor = theme.colors.border
        badgeToggleLabel?.font = WMFFont.for(.body)
        badgeToggleLabel?.textColor = theme.colors.primaryText
        
        headlineLabel.font = WMFFont.for(.boldBody)
        headlineLabel.textColor = theme.colors.primaryText
        
        subtitleLabel.font = WMFFont.for(.subheadline)
        subtitleLabel.textColor = theme.colors.primaryText
        
        closeButtonHostingController.view.backgroundColor = theme.colors.paperBackground
        
        var config = primaryButton.configuration
        config?.baseBackgroundColor = theme.colors.link
        config?.baseForegroundColor = theme.colors.paperBackground
        primaryButton.configuration = config
    }
}
