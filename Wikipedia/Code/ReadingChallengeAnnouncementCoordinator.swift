import UIKit
import WMFData
import WMFComponents
import WMF
import WMFNativeLocalizations
import SwiftUI

@MainActor
final class ReadingChallengeAnnouncementCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    private let fromWidgetJoinChallengeButton: Bool
    private let isLoggedIn: Bool

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fromWidgetJoinChallengeButton: Bool, isLoggedIn: Bool) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fromWidgetJoinChallengeButton = fromWidgetJoinChallengeButton
        self.isLoggedIn = isLoggedIn
    }

    var onComplete: ((Bool) -> Void)?
    
    @discardableResult
    func start() -> Bool {
        
        Task { [weak self] in
            guard let self else { return }
            if fromWidgetJoinChallengeButton {
                presentFullPageAnnouncement()
            } else {
                guard await WMFActivityTabDataController.shared.shouldShowReadingChallengeAnnouncement() else {
                    self.onComplete?(false)
                    return
                }
                presentFullPageAnnouncement()
            }
        }

        return true
    }
    
    // MARK: - Full page announcement
    
    private func presentFullPageAnnouncement() {
        
        let formatter = DateFormatter.wmfMonthDayDateFormatter
        let startText = formatter.string(from: ReadingChallengeStateConfig.startDate)
        let endText = formatter.string(from: ReadingChallengeStateConfig.endDate)
        
        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .bookPagesFill),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item1-title",
                value: "Read 1 article a day for 25 days",
                comment: "Title for reading challenge onboarding first item."
            ),
            subtitle: String.localizedStringWithFormat(WMFLocalizedString(
                "reading-challenge-announcement-item1-subtitle",
                value: "Join the challenge anytime between %1$@ and %2$@, complete your 25 days on your own timeline.",
                comment: "Subtitle for reading challenge onboarding first item. %1$@ is a localized start day and month name, %2$@ is a localized end date and month name."
            ), startText, endText),
            fillIconBackground: false
        )

        let secondItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .appGiftFill),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item2-title",
                value: "Win prizes",
                comment: "Title for reading challenge onboarding second item."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-announcement-item2-subtitle",
                value: "Complete a 25-day reading streak while the challenge is live to win special prizes.",
                comment: "Subtitle for reading challenge onboarding second item."
            ),
            fillIconBackground: false
        )

        let thirdItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .widgetAdd),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item3-title",
                value: "Install the widget",
                comment: "Title for reading challenge onboarding third item."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-announcement-item3-subtitle",
                value: "Get helpful reminders and motivation with our adorable birthday mascot Baby Globe.",
                comment: "Subtitle for reading challenge onboarding third item."
            ),
            fillIconBackground: false
        )

        let subtitle = WMFLocalizedString(
            "reading-challenge-announcement-subtitle",
            value: "Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.",
            comment: "Notice about privacy for reading challenge"
        )

        let onboardingViewModel = WMFOnboardingViewModel(
            title: WMFLocalizedString(
                "reading-challenge-announcement-title",
                value: "Celebrate Wikipedia's 25th birthday by joining the 25-day reading challenge!",
                comment: "Title for the reading challenge onboarding view."
            ),
            cells: [firstItem, secondItem, thirdItem],
            primaryButtonTitle: WMFLocalizedString(
                "reading-challenge-announcement-cta",
                value: "Join the challenge",
                comment: "Primary button title"
            ),
            secondaryButtonTitle: WMFLocalizedString(
                "reading-challenge-announcement-secondary-cta",
                value: "Learn more",
                comment: "Secondary button title"
            ),
            subtitle: subtitle
        )

        let onboardingController = WMFOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.delegate = self
        onboardingController.closeButtonAction = { [weak self] in
            self?.navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                self?.onComplete?((true))
            }
        }

        let navController = WMFComponentNavigationController(rootViewController: onboardingController, modalPresentationStyle: .pageSheet)

        markSeen()

        navigationController.present(navController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    private func markSeen() {
        Task {
            await WMFActivityTabDataController.shared.setHasSeenFullPageAnnouncement()
        }
    }

    private func enroll() {
        Task {
            await WMFActivityTabDataController.shared.setEnrolledInReadingChallenge(true)
            WidgetController.shared.reloadReadingChallengeWidget()
        }
    }

    var learnMoreURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "25th Birthday Reading Challenge"], section: nil, language: appLanguage)
    }
    
    // MARK: - Widget Announcement
    
    let title = WMFLocalizedString(
        "reading-challenge-widget-announcement-title",
        value: "Install the 25-day reading challenge widget",
        comment: "Title for the reading challenge widget announcement sheet."
    )
    
    let body = WMFLocalizedString(
        "reading-challenge-widget-announcement-body",
        value: "Baby Globe is cheering you on. Add the Reading Challenge widget to track your progress from your homescreen.",
        comment: "Body text for the reading challenge widget announcement sheet."
    )
    
    private func presentWidgetAnnouncement() {
        if UIDevice.current.userInterfaceIdiom == .pad && navigationController.traitCollection.horizontalSizeClass == .regular {
            let controller = ReadingChallengeWidgetAnnouncementViewController(
                title: title,
                body: body,
                primaryButtonTitle: CommonStrings.gotItButtonTitle,
                image: UIImage(named: "readingChallengeWidget"),
                backgroundImage: UIImage(named: "readingChallengeBackground"),
                backgroundImageHeight: 320,
                theme: theme
            )
            controller.primaryButtonAction = { [weak self] in
                self?.onComplete?(true)
            }
            controller.closeButtonAction = { [weak self] in
                self?.onComplete?(true)
            }
            controller.modalPresentationStyle = .formSheet
            controller.preferredContentSize = CGSize(width: 540, height: 0)
            navigationController.present(controller, animated: true)
        } else {
            let viewModel = makeWidgetAnnouncementViewModel()
            let controller = WMFFeatureAnnouncementViewController(viewModel: viewModel)
            if let sheet = controller.sheetPresentationController {

                viewModel.primaryButtonAction = { [weak self] in
                    self?.navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                        self?.onComplete?(true)
                    }
                }
                viewModel.closeButtonAction = { [weak self] in
                    self?.navigationController.dismiss(animated: true) {
                        self?.onComplete?(true)
                    }
                }
                
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                
                controller.modalPresentationStyle = .pageSheet
                sheet.detents = [.medium()]
                
                navigationController.present(controller, animated: true)
            }
        }
    }
        
    private func makeWidgetAnnouncementViewModel() -> WMFFeatureAnnouncementViewModel {
        WMFFeatureAnnouncementViewModel(
            title: title,
            body: body,
            primaryButtonTitle: CommonStrings.gotItButtonTitle,
            image: UIImage(named: "readingChallengeWidget"),
            backgroundImage: UIImage(named: "readingChallengeBackground"),
            backgroundImageHeight: 220,
            primaryButtonAction: {},
            closeButtonAction: nil
        )
    }
}

// MARK: - WMFOnboardingViewDelegate

@MainActor
extension ReadingChallengeAnnouncementCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {
        if dataStore.authenticationManager.authStateIsPermanent {
            enroll()
            navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                if !fromWidgetJoinChallengeButton {
                    self.presentWidgetAnnouncement()
                } else {
                    self.onComplete?(true)
                }
            }
        } else {
            let alert = UIAlertController(
                title: WMFLocalizedString("reading-challenge-login-title", value: "Log in to join the challenge", comment: "Title for alert that asks users to log in to join the reading challenge"),
                message: WMFLocalizedString("reading-challenge-login-message", value: "Log in or create an account to track your progress towards the reading challenge.", comment: "Message for alert that asks users to log in to join the reading challenge"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: CommonStrings.joinLoginTitle, style: .default) { [weak self] _ in
                guard let self else { return }
                self.navigationController.presentedViewController?.dismiss(animated: true) {
                    let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme, loggingCategory: .login)
                    
                    loginCoordinator.loginSuccessCompletion = { [weak self] in
                        guard let self else { return }
                        if let loginVC = self.navigationController.presentedViewController {
                            loginVC.dismiss(animated: true) { [weak self] in
                                guard let self else { return }
                                enroll()
                                if !fromWidgetJoinChallengeButton {
                                    presentWidgetAnnouncement()
                                } else {
                                    onComplete?(true)
                                }
                            }
                        }
                    }
                    
                    loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
                        guard let self else { return }
                        if let createAccountVC = self.navigationController.presentedViewController {
                            createAccountVC.dismiss(animated: true) { [weak self] in
                                guard let self else { return }
                                enroll()
                                if !fromWidgetJoinChallengeButton {
                                    presentWidgetAnnouncement()
                                } else {
                                    onComplete?(true)
                                }
                            }
                        }
                    }
                    
                    loginCoordinator.start()
                }
            })
            alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
            navigationController.presentedViewController?.present(alert, animated: true)
        }
    }
    
    func onboardingDidSwipeToDismiss() {
        self.onComplete?(true)
    }

    func onboardingViewDidClickSecondaryButton() {
        guard let url = learnMoreURL else { return }

        let config = SinglePageWebViewController.StandardConfig(
            url: url,
            useSimpleNavigationBar: true
        )

        let webVC = SinglePageWebViewController(
            configType: .standard(config),
            theme: self.theme
        )

        navigationController.presentedViewController?.children.first.flatMap { $0 as? UINavigationController }?.pushViewController(webVC, animated: true)
        ?? (navigationController.presentedViewController as? UINavigationController)?.pushViewController(webVC, animated: true)
    }
}

// MARK: - Widget Announcement View Controller

@MainActor
final class ReadingChallengeWidgetAnnouncementViewController: UIViewController {

    var primaryButtonAction: (() -> Void)?
    var closeButtonAction: (() -> Void)?

    private let titleText: String
    private let bodyText: String
    private let primaryButtonTitleText: String
    private let image: UIImage?
    private let backgroundImage: UIImage?
    private let backgroundImageHeight: CGFloat
    private let theme: Theme

    init(
        title: String,
        body: String,
        primaryButtonTitle: String,
        image: UIImage?,
        backgroundImage: UIImage?,
        backgroundImageHeight: CGFloat,
        theme: Theme
    ) {
        self.titleText = title
        self.bodyText = body
        self.primaryButtonTitleText = primaryButtonTitle
        self.image = image
        self.backgroundImage = backgroundImage
        self.backgroundImageHeight = backgroundImageHeight
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var closeButtonHostingController: UIHostingController<WMFLargeCloseButton> = {
        guard let button = WMFLargeCloseButton(imageType: .plainX, action: { [weak self] in
            self?.handleClose()
        }) else {
            fatalError("Failed to create WMFLargeCloseButton")
        }
        let hostingController = UIHostingController(rootView: button)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        return hostingController
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textAlignment = .natural
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textAlignment = .natural
        return l
    }()

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 14
        return iv
    }()

    private let widgetImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.18
        iv.layer.shadowOffset = CGSize(width: 0, height: 6)
        iv.layer.shadowRadius = 12
        iv.clipsToBounds = false
        return iv
    }()

    private let primaryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(closeButtonHostingController)
        closeButtonHostingController.didMove(toParent: self)
        setupLayout()
        applyContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let fittingSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let size = view.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if preferredContentSize.height != size.height {
            preferredContentSize = size
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(closeButtonHostingController.view)
        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)
        view.addSubview(backgroundImageView)
        backgroundImageView.addSubview(widgetImageView)
        view.addSubview(primaryButton)

        NSLayoutConstraint.activate([
            closeButtonHostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButtonHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            closeButtonHostingController.view.widthAnchor.constraint(equalToConstant: 44),
            closeButtonHostingController.view.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: closeButtonHostingController.view.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            backgroundImageView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            backgroundImageView.heightAnchor.constraint(
                equalTo: backgroundImageView.widthAnchor,
                multiplier: 2.0 / 3.0
            ),

            widgetImageView.centerXAnchor.constraint(equalTo: backgroundImageView.centerXAnchor),
            widgetImageView.centerYAnchor.constraint(equalTo: backgroundImageView.centerYAnchor),
            widgetImageView.widthAnchor.constraint(equalToConstant: 180),
            widgetImageView.heightAnchor.constraint(equalToConstant: 180),

            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            primaryButton.topAnchor.constraint(equalTo: backgroundImageView.bottomAnchor, constant: 16),
            primaryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        primaryButton.addTarget(self, action: #selector(handlePrimary), for: .touchUpInside)
    }

    // MARK: - Content

    private func applyContent() {
        titleLabel.text = titleText
        titleLabel.font = WMFFont.for(.boldTitle3)
        titleLabel.textColor = theme.colors.primaryText

        bodyLabel.text = bodyText
        bodyLabel.font = WMFFont.for(.subheadline)
        bodyLabel.textColor = theme.colors.secondaryText

        backgroundImageView.image = backgroundImage
        widgetImageView.image = image

        view.backgroundColor = theme.colors.paperBackground

        var buttonConfig = primaryButton.configuration ?? UIButton.Configuration.filled()
        buttonConfig.title = primaryButtonTitleText
        buttonConfig.cornerStyle = .capsule
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        primaryButton.configuration = buttonConfig
        primaryButton.configurationUpdateHandler = { [weak self] button in
            guard let self else { return }
            var config = button.configuration
            config?.baseBackgroundColor = self.theme.colors.link
            config?.baseForegroundColor = .white
            button.configuration = config
        }
    }

    // MARK: - Actions

    private func handleClose() {
        dismiss(animated: true) { [weak self] in
            self?.closeButtonAction?()
        }
    }

    @objc private func handlePrimary() {
        dismiss(animated: true) { [weak self] in
            self?.primaryButtonAction?()
        }
    }
}
