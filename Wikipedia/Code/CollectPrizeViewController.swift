import WMFComponents
import WMF

final class CollectPrizeViewController: UIViewController, Themeable {
    
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
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = WMFSFSymbolIcon.for(symbol: .xMark)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = WMFLocalizedString("collect-prize-title", value: "Collect your prize!", comment: "Title for collect prize modal sheet")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        label.text = WMFLocalizedString("collect-prize-subtitle", value: "Celebrate completing the challenge with 15%% off at the Wikipedia Store.", comment: "Subtitle for collect prize modal. Please leave %% unchanged for proper formatting.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var ctaButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = WMFLocalizedString("collect-prize-cta", value: "Get 15%% off at the store", comment: "CTA button title for collect prize modal. Please leave %% unchanged for proper formatting.")
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        apply(theme: theme)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(prizeImageView)
        view.addSubview(headlineLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(ctaButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -56),
            
            prizeImageView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            prizeImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            prizeImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            prizeImageView.heightAnchor.constraint(equalToConstant: 220),
            
            headlineLabel.topAnchor.constraint(equalTo: prizeImageView.bottomAnchor, constant: 20),
            headlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            ctaButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func ctaTapped() {
        guard let url = URL(string: "https://store.wikimedia.org/discount/Widget15") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Themeable
    
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        
        titleLabel.font = WMFFont.for(.body)
        titleLabel.textColor = theme.colors.primaryText
        
        headlineLabel.font = WMFFont.for(.boldBody)
        headlineLabel.textColor = theme.colors.primaryText
        
        subtitleLabel.font = WMFFont.for(.subheadline)
        subtitleLabel.textColor = theme.colors.secondaryText
        
        closeButton.tintColor = theme.colors.accent
        closeButton.backgroundColor = theme.colors.baseBackground
        
        var config = ctaButton.configuration
        config?.baseBackgroundColor = theme.colors.link
        config?.baseForegroundColor = theme.colors.paperBackground
        ctaButton.configuration = config
    }
}
