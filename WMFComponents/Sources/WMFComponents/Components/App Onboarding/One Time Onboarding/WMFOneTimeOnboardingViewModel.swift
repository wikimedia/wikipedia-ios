import UIKit
import WMFNativeLocalizations
import WMFData

@MainActor
public final class WMFOneTimeOnboardingViewModel: ObservableObject {

    // MARK: - Feature Item

    public struct FeatureItem: Identifiable {
        public let id = UUID()
        public let symbol: WMFSFSymbolIcon
        public let title: String
        public let body: String
    }

    // MARK: - Localized Strings

    let title = WMFLocalizedString(
        "one-time-onboarding-title",
        value: "Explore is now Home, with a new look",
        comment: "Title of the one-time onboarding sheet shown to existing users after the Explore tab is renamed to Home."
    )

    let customizeButtonTitle = WMFLocalizedString(
        "one-time-onboarding-customize-button",
        value: "Customize my feed",
        comment: "Primary button on the one-time onboarding sheet that opens the feed customization flow."
    )

    let autoSetupButtonTitle = WMFLocalizedString(
        "one-time-onboarding-auto-setup-button",
        value: "Set it up for me",
        comment: "Secondary button on the one-time onboarding sheet that automatically configures the feed without customization."
    )

    // MARK: - Feature Items

    lazy var featureItems: [FeatureItem] = [
        FeatureItem(
            symbol: .house,
            title: WMFLocalizedString(
                "one-time-onboarding-feature-name-title",
                value: "A new name",
                comment: "Title of the 'A new name' feature item on the one-time onboarding sheet."
            ),
            body: WMFLocalizedString(
                "one-time-onboarding-feature-name-body",
                value: "The Explore feed is now Home, in the same spot as before.",
                comment: "Description of the 'A new name' feature item on the one-time onboarding sheet."
            )
        ),
        FeatureItem(
            symbol: .squareSplit,
            title: WMFLocalizedString(
                "one-time-onboarding-feature-feed-title",
                value: "Your feed, two ways",
                comment: "Title of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
            ),
            body: WMFLocalizedString(
                "one-time-onboarding-feature-feed-body",
                value: "Discover articles personalized to your interests in For You, or browse Wikipedia's best editorial content in Community.",
                comment: "Description of the 'Your feed, two ways' feature item on the one-time onboarding sheet."
            )
        ),
        FeatureItem(
            symbol: .sliderHorizontal3,
            title: WMFLocalizedString(
                "one-time-onboarding-feature-control-title",
                value: "Stay in control",
                comment: "Title of the 'Stay in control' feature item on the one-time onboarding sheet."
            ),
            body: WMFLocalizedString(
                "one-time-onboarding-feature-control-body",
                value: "Every recommendation tells you exactly why it's there. You can update your preferences anytime in Settings.",
                comment: "Description of the 'Stay in control' feature item on the one-time onboarding sheet."
            )
        ),
        FeatureItem(
            symbol: .globeAmericas,
            title: WMFLocalizedString(
                "one-time-onboarding-feature-languages-title",
                value: "Every language, fully personalized",
                comment: "Title of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
            ),
            body: WMFLocalizedString(
                "one-time-onboarding-feature-languages-body",
                value: "Reading in multiple languages? Each one gets its own experience. Just switch and your new feed is ready.",
                comment: "Description of the 'Every language, fully personalized' feature item on the one-time onboarding sheet."
            )
        )
    ]

    // MARK: - Actions

    public var onCustomize: (() -> Void)?
    public var onAutoSetup: (() -> Void)?

    public init() {}
}
