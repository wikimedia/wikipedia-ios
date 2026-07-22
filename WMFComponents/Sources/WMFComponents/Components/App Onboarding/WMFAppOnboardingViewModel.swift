import Foundation
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFAppOnboardingViewModel: ObservableObject {

    public enum Step: Equatable {
        case intro
        case dataPrivacy
        case languages
        case personalizationIntro
        case interests
        case feedPreference
        case loading

        var isPersonalization: Bool {
            switch self {
            case .personalizationIntro, .interests, .feedPreference:
                return true
            case .intro, .dataPrivacy, .languages, .loading:
                return false
            }
        }
    }

    public struct LanguageItem: Identifiable, Equatable {
        public let id: String
        public let displayName: String
        public let isPrimary: Bool

        public init(id: String, displayName: String, isPrimary: Bool) {
            self.id = id
            self.displayName = displayName
            self.isPrimary = isPrimary
        }
    }

    // MARK: - Strings

    /// VoiceOver label for the wordmark image on the intro step (the visible "WIKIPEDIA" is
    /// an image asset). Localized: the name is transliterated in non-Latin scripts.
    let introWordmark = CommonStrings.plainWikipediaName
    let introTitle = WMFLocalizedString("app-onboarding-intro-title", value: "All the world’s knowledge", comment: "Title of the first app onboarding screen.")
    let introBody = WMFLocalizedString("app-onboarding-intro-body", value: "Wikipedia is a free online encyclopedia with 65 million articles collaboratively written and maintained in more than 300 languages by a community of volunteers.", comment: "Description on the first app onboarding screen.")
    let introLearnMore = WMFLocalizedString("app-onboarding-intro-learn-more", value: "Learn more about Wikipedia", comment: "Title of the link on the first app onboarding screen that opens a web view with more information about Wikipedia.")

    let dataPrivacyTitle = WMFLocalizedString("app-onboarding-data-privacy-title", value: "Data & Privacy", comment: "Title of the Data & Privacy app onboarding screen.")
    let dataPrivacyBody = WMFLocalizedString("app-onboarding-data-privacy-body", value: "We believe that you should not have to provide personal information to participate in the free knowledge movement. Usage data collected for this app is anonymous.", comment: "Description on the Data & Privacy app onboarding screen.")
    let dataPrivacyLinksFormat = WMFLocalizedString("app-onboarding-data-privacy-links-format", value: "Learn more about our %1$@ and %2$@", comment: "Sentence on the Data & Privacy app onboarding screen containing two tappable links. %1$@ is replaced with the privacy policy link text, %2$@ with the terms of use link text.")
    let dataPrivacyPolicyLinkText = WMFLocalizedString("app-onboarding-data-privacy-policy-link", value: "privacy policy", comment: "Tappable privacy policy link text, inserted into a sentence on the Data & Privacy app onboarding screen.")
    let dataPrivacyTermsLinkText = WMFLocalizedString("app-onboarding-data-privacy-terms-link", value: "terms of use", comment: "Tappable terms of use link text, inserted into a sentence on the Data & Privacy app onboarding screen.")

    let languagesTitle = WMFLocalizedString("app-onboarding-languages-title", value: "Read in more than 300 languages", comment: "Title of the languages app onboarding screen.")
    let languagesNotice = WMFLocalizedString("app-onboarding-languages-notice", value: "We’ve noticed the following languages on your device:", comment: "Text above the detected device languages list on the languages app onboarding screen.")
    let languagesPrimaryLabel = WMFLocalizedString("app-onboarding-languages-primary-label", value: "Primary", comment: "Label shown under the user's primary language on the languages app onboarding screen.")
    let languagesAddOrEdit = WMFLocalizedString("app-onboarding-languages-add-edit", value: "Add or edit your languages", comment: "Title of the button on the languages app onboarding screen that opens the preferred languages editor.")

    let personalizationTitle = WMFLocalizedString("app-onboarding-personalization-title", value: "Follow your curiosity", comment: "Title of the personalization intro app onboarding screen.")
    let personalizationBody1 = WMFLocalizedString("app-onboarding-personalization-body-1", value: "Select topics that interest you and we will personalize your feed.", comment: "First description line on the personalization intro app onboarding screen.")
    let personalizationBody2 = WMFLocalizedString("app-onboarding-personalization-body-2", value: "We collect minimal data that is anonymized.", comment: "Second description line on the personalization intro app onboarding screen.")

    let loadingTitle = WMFLocalizedString("app-onboarding-loading-title", value: "Let’s build your feed…", comment: "Title shown on the final app onboarding screen while the user's feed is loading.")

    let skipTitle = CommonStrings.skipTitle
    let nextAccessibilityLabel = CommonStrings.nextTitle

    // MARK: - State

    /// Onboarding steps in presentation order. Future steps can be appended here; personalization
    /// sub-steps automatically join the page dots.
    let steps: [Step] = [.intro, .dataPrivacy, .languages, .personalizationIntro, .interests, .feedPreference, .loading]

    /// The Lottie loading step has no toolbar (no Skip/dots/chevron) and auto-completes.
    let loadingAnimationName = "onboarding-loading"

    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var languages: [LanguageItem]

    public let interestsViewModel: WMFHomeFeedInterestsSettingsViewModel
    public let feedPreferenceViewModel: WMFAppOnboardingFeedPreferenceViewModel

    // MARK: - App-side actions

    let didTapLearnMoreAboutWikipedia: () -> Void
    let didTapPrivacyPolicy: () -> Void
    let didTapTermsOfUse: () -> Void
    let didTapAddLanguages: () -> Void
    let onCompletion: () -> Void

    public init(languages: [LanguageItem],
                interestsViewModel: WMFHomeFeedInterestsSettingsViewModel,
                feedPreferenceViewModel: WMFAppOnboardingFeedPreferenceViewModel,
                didTapLearnMoreAboutWikipedia: @escaping () -> Void,
                didTapPrivacyPolicy: @escaping () -> Void,
                didTapTermsOfUse: @escaping () -> Void,
                didTapAddLanguages: @escaping () -> Void,
                onCompletion: @escaping () -> Void) {
        self.languages = languages
        self.interestsViewModel = interestsViewModel
        self.feedPreferenceViewModel = feedPreferenceViewModel
        self.didTapLearnMoreAboutWikipedia = didTapLearnMoreAboutWikipedia
        self.didTapPrivacyPolicy = didTapPrivacyPolicy
        self.didTapTermsOfUse = didTapTermsOfUse
        self.didTapAddLanguages = didTapAddLanguages
        self.onCompletion = onCompletion
    }

    public var currentStep: Step {
        return steps[currentStepIndex]
    }

    var showsSkipAndDots: Bool {
        return currentStep.isPersonalization
    }

    /// The loading step covers the whole screen with no navigation chrome.
    var showsToolbar: Bool {
        return currentStep != .loading
    }

    var personalizationSteps: [Step] {
        return steps.filter { $0.isPersonalization }
    }

    var currentDotIndex: Int? {
        return personalizationSteps.firstIndex(of: currentStep)
    }

    /// Spoken by VoiceOver in place of the decorative page dots.
    var pageIndicatorAccessibilityLabel: String? {
        guard let index = currentDotIndex else { return nil }
        let format = WMFLocalizedString("app-onboarding-page-indicator", value: "Page %1$d of %2$d", comment: "Accessibility label for the onboarding page indicator dots. %1$d is the current page number, %2$d is the total number of pages.")
        return String.localizedStringWithFormat(format, index + 1, personalizationSteps.count)
    }

    /// Advances to the next step, or completes onboarding when on the last step.
    public func advance() {
        // Interests are final once the user leaves the interests step — start fetching the
        // feed preference previews now for a head start over the step's onAppear.
        if currentStep == .interests {
            feedPreferenceViewModel.loadIfNeeded()
        }

        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        } else {
            onCompletion()
        }
    }

    /// Skips the remaining steps and completes onboarding. Skipping applies the default
    /// feed preference regardless of any selection made on the feed preference step.
    public func skip() {
        feedPreferenceViewModel.resetSelectionToDefault()
        onCompletion()
    }

    private var loadingTask: Task<Void, Never>?

    /// Drives the loading step: loads the selected feed and waits for the animation to loop at
    /// least once, then completes onboarding. `minimumDisplay` is the animation's loop duration,
    /// supplied by the view (which owns the Lottie animation). The feed load is capped by
    /// `maximumWait` so a slow or hung fetch can never trap the user on the loading screen.
    func completeAfterLoadingFeed(minimumDisplay: TimeInterval, maximumWait: TimeInterval = 8) {
        guard loadingTask == nil else { return }
        loadingTask = Task { [weak self] in
            guard let self else { return }
            async let feedLoaded: Void = loadFeedBounded(maximumWait: maximumWait)
            async let minimumElapsed: Void = Self.sleep(minimumDisplay)
            _ = await (feedLoaded, minimumElapsed)
            guard !Task.isCancelled else { return }
            onCompletion()
        }
    }

    /// Returns once the feed has loaded or `maximumWait` elapses, whichever comes first.
    /// Deliberately not a task group: a group waits for all children before returning, so a
    /// hung fetch (URLSession doesn't cooperate with task cancellation here) would defeat the
    /// bound. This races unstructured tasks and lets the loser finish in the background.
    private func loadFeedBounded(maximumWait: TimeInterval) async {
        let resumeState = LoadFeedResumeState()
        let feedPreferenceViewModel = feedPreferenceViewModel
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task {
                await feedPreferenceViewModel.loadSelectedFeed()
                resumeState.resumeOnce(continuation)
            }
            Task {
                await Self.sleep(maximumWait)
                resumeState.resumeOnce(continuation)
            }
        }
    }

    /// Ensures the first-wins race above resumes its continuation exactly once.
    private final class LoadFeedResumeState: @unchecked Sendable {
        private let lock = NSLock()
        private var isResumed = false

        func resumeOnce(_ continuation: CheckedContinuation<Void, Never>) {
            lock.lock()
            defer { lock.unlock() }
            guard !isResumed else { return }
            isResumed = true
            continuation.resume()
        }
    }

    private static func sleep(_ seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }

    public func updateLanguages(_ items: [LanguageItem]) {
        languages = items
    }
}
