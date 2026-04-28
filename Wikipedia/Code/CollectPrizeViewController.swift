import WMFComponents
import WMF
import Combine
import SwiftUI
import WMFNativeLocalizations

final class CollectPrizeViewController: UIViewController, Themeable, WMFNavigationBarConfiguring {

    // MARK: - Properties

    private var theme: Theme

    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

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
        setupLayout()
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: CommonStrings.collectPrizeTitle,
            customView: nil,
            alignment: .hidden
        )
        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(closeTapped),
            alignment: .leading
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    private func setupLayout() {
        view.addSubview(prizeImageView)
        view.addSubview(headlineLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(primaryButton)

        prizeImageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        NSLayoutConstraint.activate([
            prizeImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
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
            primaryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
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
        headlineLabel.font = WMFFont.for(.boldBody)
        headlineLabel.textColor = theme.colors.primaryText
        subtitleLabel.font = WMFFont.for(.subheadline)
        subtitleLabel.textColor = theme.colors.primaryText
        var config = primaryButton.configuration
        config?.baseBackgroundColor = theme.colors.link
        config?.baseForegroundColor = theme.colors.paperBackground
        primaryButton.configuration = config
    }
}
