import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

/// Presents the app-launch onboarding flow and handles its app-side navigation
/// (web views, the preferred languages editor) and completion.
@MainActor
final class AppOnboardingCoordinator: NSObject {

    private weak var presentingViewController: UIViewController?
    private let dataStore: MWKDataStore
    private let theme: Theme
    private let willDismiss: () -> Void
    private let completion: () -> Void

    private var viewModel: WMFAppOnboardingViewModel?
    private(set) var hostingController: WMFAppOnboardingHostingController?
    
    private var homeFeedInstrument: InstrumentImpl?

    init(presentingViewController: UIViewController, dataStore: MWKDataStore, theme: Theme, willDismiss: @escaping () -> Void, completion: @escaping () -> Void) {
        self.presentingViewController = presentingViewController
        self.dataStore = dataStore
        self.theme = theme
        self.willDismiss = willDismiss
        self.completion = completion
    }

    func start() {
        // Topics and articles derive from the app's primary language, not any feed-selected language
        let language = preferredWMFLanguages().first ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)

        // Warm the day cache so the feed preference step's community previews (and the Home
        // feed itself) are ready by the time the user gets there. Interests-independent.
        Task {
            try? await WMFHomeDataController.shared.fetchCommunity(project: project)
        }

        let interestsViewModel = WMFHomeFeedInterestsSettingsViewModel(
            project: project,
            searchLanguages: preferredWMFLanguages(),
            logDidTapTopic: { [weak self] in
                self?.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "topic_select")
            },
            logDidTapArticle: { [weak self] in
                self?.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "article_select")
            },
            logDidTapDeselectAll: { [weak self] in
                self?.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "deselect_all")
            }
        )
        let feedPreferenceViewModel = WMFAppOnboardingFeedPreferenceViewModel(
            project: project,
            logImpression: { [weak self] noInterests in
                let actionSubtype: String? = noInterests ? "no_interests" : nil
                self?.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "feed_order_customize", actionSubtype: actionSubtype)
            },
            logDidTapCommunity: { [weak self] in
                self?.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_order_customize", elementId: "community_first")
            },
            logDidTapPersonalized: { [weak self] in
                self?.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_order_customize", elementId: "for_you_first")
            }
        )
        
        let viewModel = WMFAppOnboardingViewModel(
            languages: preferredLanguageItems(),
            interestsViewModel: interestsViewModel,
            feedPreferenceViewModel: feedPreferenceViewModel,
            didTapLearnMoreAboutWikipedia: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.aboutWikipediaURLString)
            },
            didTapPrivacyPolicy: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.privacyPolicyURLString)
            },
            didTapTermsOfUse: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.termsOfUseURLString)
            },
            didTapAddLanguages: { [weak self] in
                self?.presentPreferredLanguages()
            },
            onCompletion: { [weak self] in
                self?.finish()
            },
            logImpression: { [weak self] step in
                
                guard let self else { return }
                switch step {
                case .personalizationIntro:
                    self.homeFeedInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-home-feed")
                    self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "feed_entry")
                case .interests:
                    self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "feed_customize")
                case .feedPreference:
                    // handling it in child view model so that we can capture "no interests" subtype. The "no interests" data is not available from this hook, the child view model has to load the data first.
                    break
                case .loading:
                    self.homeFeedInstrument?.submitInteraction(action: "impression", actionSource: "feed_loading")
                    break
                case .intro, .languages, .dataPrivacy:
                    //todo
                    break
                }
            },
            logSkip: { [weak self] step in
                
                guard let self else { return }
                switch step {
                case .personalizationIntro:
                    self.homeFeedInstrument?.startFunnel(name: "feed_customize").submitInteraction(action: "click", actionSource: "feed_entry", elementId: "skip_button")
                case .interests:
                    self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "skip_button")
                case .feedPreference:
                    let actionSubtype: String? = !feedPreferenceViewModel.isPersonalizedAvailable ? "no_interests" : nil
                    self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_order_customize", actionSubtype: actionSubtype, elementId: "skip_button")
                case .loading:
                    //todo
                    break
                case .intro, .languages, .dataPrivacy:
                    //todo
                    break
                }
                
                
            },
            logNext: { [weak self] step in
                
                guard let self else { return }
                switch step {
                case .personalizationIntro:
                    self.homeFeedInstrument?.startFunnel(name: "feed_customize").submitInteraction(action: "click", actionSource: "feed_entry", elementId: "next_button")
                case .interests:
                    self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "next_button")
                case .feedPreference:
                    let actionSubtype: String? = !feedPreferenceViewModel.isPersonalizedAvailable ? "no_interests" : nil
                    self.homeFeedInstrument?.submitInteraction(action: "click", actionSource: "feed_order_customize", actionSubtype: actionSubtype, elementId: "next_button")
                case .loading:
                    //todo
                    break
                case .intro, .languages, .dataPrivacy:
                    //todo
                    break
                }
            }
        )
        self.viewModel = viewModel

        let hostingController = WMFAppOnboardingHostingController(viewModel: viewModel)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalPresentationCapturesStatusBarAppearance = true
        self.hostingController = hostingController
        presentingViewController?.present(hostingController, animated: false)
    }


    func startCondensed(instrument: InstrumentImpl) {
        let language = preferredWMFLanguages().first ?? WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)

        Task {
            try? await WMFHomeDataController.shared.fetchCommunity(project: project)
        }

        let interestsViewModel = WMFHomeFeedInterestsSettingsViewModel(
            project: project,
            searchLanguages: preferredWMFLanguages(),
            logDidTapTopic: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "topic_select")
            },
            logDidTapArticle: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "article_select")
            },
            logDidTapDeselectAll: {
                instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "deselect_all")
            }
        )
        let feedPreferenceViewModel = WMFAppOnboardingFeedPreferenceViewModel(
            project: project,
            logImpression: { noInterests in
                let actionSubtype: String? = noInterests ? "no_interests" : nil
                instrument.submitInteraction(action: "impression", actionSource: "feed_order_customize", actionSubtype: actionSubtype)
            },
            logDidTapCommunity: {
                instrument.submitInteraction(action: "click", actionSource: "feed_order_customize", elementId: "community_first")
            },
            logDidTapPersonalized: {
                instrument.submitInteraction(action: "click", actionSource: "feed_order_customize", elementId: "for_you_first")
            }
        )

        let viewModel = WMFAppOnboardingViewModel(
            languages: preferredLanguageItems(),
            interestsViewModel: interestsViewModel,
            feedPreferenceViewModel: feedPreferenceViewModel,
            didTapLearnMoreAboutWikipedia: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.aboutWikipediaURLString)
            },
            didTapPrivacyPolicy: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.privacyPolicyURLString)
            },
            didTapTermsOfUse: { [weak self] in
                self?.presentWebView(urlString: CommonStrings.termsOfUseURLString)
            },
            didTapAddLanguages: { [weak self] in
                self?.presentPreferredLanguages()
            },
            onCompletion: { [weak self] in
                self?.finish()
            },
            logImpression: { step in
                switch step {
                case .personalizationIntro:
                    assertionFailure("Condensed flow should not see personalization intro.")
                case .interests:
                    instrument.submitInteraction(action: "impression", actionSource: "feed_customize")
                case .feedPreference:
                    // handling it in child view model so that we can capture "no interests" subtype.  The "no interests" data is not available from this hook, the child view model has to load the data first.
                    break
                case .loading:
                    instrument.submitInteraction(action: "impression", actionSource: "feed_loading")
                    break
                case .intro, .languages, .dataPrivacy:
                    assertionFailure("Condensed flow should not see intro, languages, or data privacy.")
                }
            },
            logSkip: { step in
                switch step {
                case .personalizationIntro:
                    assertionFailure("Condensed flow should not see personalization intro.")
                case .interests:
                    instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "skip_button")
                case .feedPreference:
                    let actionSubtype: String? = !feedPreferenceViewModel.isPersonalizedAvailable ? "no_interests" : nil
                    instrument.submitInteraction(action: "click", actionSource: "feed_order_customize", actionSubtype: actionSubtype, elementId: "skip_button")
                case .loading:
                    //todo
                    break
                case .intro, .languages, .dataPrivacy:
                    assertionFailure("Condensed flow should not see intro, languages, or data privacy.")
                }
            },
            logNext: { step in
                
                 switch step {
                 case .personalizationIntro:
                     assertionFailure("Condensed flow should not see personalization intro.")
                 case .interests:
                     instrument.submitInteraction(action: "click", actionSource: "feed_customize", elementId: "next_button")
                 case .feedPreference:
                     let actionSubtype: String? = !feedPreferenceViewModel.isPersonalizedAvailable ? "no_interests" : nil
                     instrument.submitInteraction(action: "click", actionSource: "feed_order_customize", actionSubtype: actionSubtype, elementId: "next_button")
                 case .loading:
                     //todo
                     break
                 case .intro, .languages, .dataPrivacy:
                     assertionFailure("Condensed flow should not see intro, languages, or data privacy.")
                 }
            }
        )

        viewModel.jumpToStep(.interests)

        self.viewModel = viewModel

        let hostingController = WMFAppOnboardingHostingController(viewModel: viewModel)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalPresentationCapturesStatusBarAppearance = true
        self.hostingController = hostingController
        presentingViewController?.present(hostingController, animated: true)
    }

    // MARK: - Languages

    private func preferredLanguageItems() -> [WMFAppOnboardingViewModel.LanguageItem] {
        return dataStore.languageLinkController.preferredLanguages.enumerated().map { index, language in
            WMFAppOnboardingViewModel.LanguageItem(id: language.contentLanguageCode, displayName: language.name, isPrimary: index == 0)
        }
    }

    private func preferredWMFLanguages() -> [WMFLanguage] {
        return dataStore.languageLinkController.preferredLanguages.map {
            WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode)
        }
    }

    private func presentPreferredLanguages() {
        guard let hostingController else { return }
        let languagesVC = WMFPreferredLanguagesViewController.preferredLanguagesViewController()
        languagesVC.showExploreFeedCustomizationSettings = false
        languagesVC.delegate = self
        languagesVC.apply(theme)
        let navVC = WMFComponentNavigationController(rootViewController: languagesVC, modalPresentationStyle: .overFullScreen)
        hostingController.present(navVC, animated: true)
    }

    // MARK: - Web views

    private func presentWebView(urlString: String) {
        guard let hostingController, let url = URL(string: urlString) else { return }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .fullScreen)
        hostingController.present(navVC, animated: true)
    }

    // MARK: - Completion

    private func finish() {
        if viewModel?.interestsViewModel.hasChanges == true {
            NotificationCenter.default.post(name: WMFNSNotification.forYouInterestsDidChange, object: nil)
        }
        if let seeFirst = viewModel?.feedPreferenceViewModel.selection {
            WMFHomeDataController.shared.setSeeFirstContent(seeFirst)
        }
        // Build the app's UI while onboarding still covers the screen
        willDismiss()

        hostingController?.dismiss(animated: true) { [weak self] in
            self?.completion()
        }
    }
}

extension AppOnboardingCoordinator: WMFPreferredLanguagesViewControllerDelegate {
    nonisolated func languagesController(_ controller: WMFPreferredLanguagesViewController, didUpdatePreferredLanguages languages: [MWKLanguageLink]) {
        MainActor.assumeIsolated {
            viewModel?.updateLanguages(preferredLanguageItems())
            viewModel?.interestsViewModel.updateSearchLanguages(preferredWMFLanguages())

            if let primary = preferredWMFLanguages().first {
                let project = WMFProject.wikipedia(primary)
                viewModel?.interestsViewModel.updateProject(project)
                viewModel?.feedPreferenceViewModel.updateProject(project)
                Task {
                    try? await WMFHomeDataController.shared.fetchCommunity(project: project)
                }
            }
        }
    }
}
