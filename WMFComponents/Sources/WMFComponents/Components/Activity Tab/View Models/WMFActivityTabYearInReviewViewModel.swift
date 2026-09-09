import Foundation
import WMFNativeLocalizations

@MainActor
public final class WMFActivityTabYearInReviewViewModel: ObservableObject {

    /// Supplied by the Shared Logic task's data / low-data split. Defaults to false so an
    /// unresolved value routes to the collective flow.
    @Published public var isDataRich: Bool

    public var onTap: (() -> Void)?

    public init(isDataRich: Bool = false, onTap: (() -> Void)? = nil) {
        self.isDataRich = isDataRich
        self.onTap = onTap
    }

    // MARK: - Localized strings

    private let dataRichTitle = WMFLocalizedString("activity-tab-year-in-review-data-rich-title", value: "Your Year in Review is here", comment: "Title of the Year in Review entry point on the Activity tab, shown to users with enough data for a personalized experience.")
    private let lowDataTitle = WMFLocalizedString("activity-tab-year-in-review-low-data-title", value: "Our Year in Review is here", comment: "Title of the Year in Review entry point on the Activity tab, shown to users without enough data for a personalized experience.")

    private let dataRichSubtitle = WMFLocalizedString("activity-tab-year-in-review-data-rich-subtitle", value: "Rediscover your year on Wikipedia.", comment: "Subtitle of the Year in Review entry point on the Activity tab, shown to users with enough data for a personalized experience.")
    private let lowDataSubtitle = WMFLocalizedString("activity-tab-year-in-review-low-data-subtitle", value: "Rediscover the year on Wikipedia.", comment: "Subtitle of the Year in Review entry point on the Activity tab, shown to users without enough data for a personalized experience.")

    public let ctaTitle = WMFLocalizedString("activity-tab-year-in-review-cta", value: "Get started", comment: "Button on the Year in Review entry point on the Activity tab that opens Year in Review.")

    public var title: String {
        isDataRich ? dataRichTitle : lowDataTitle
    }

    public var subtitle: String {
        isDataRich ? dataRichSubtitle : lowDataSubtitle
    }
}
