import SwiftUI
import WMFNativeLocalizations

/// The onboarding card that introduces Discover: a "New" tag, a title, a body and the Get started
/// and No thanks buttons.
public struct WMFDiscoverAnnouncementView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDiscoverAnnouncementViewModel

    private let newTag = WMFLocalizedString("discover-announcement-new-tag", value: "New", comment: "Tag on the card that introduces the Discover reading list on the Saved tab. Marks the feature as new.")
    private let title = WMFLocalizedString("discover-announcement-title", value: "Discover articles picked for you", comment: "Title of the card that introduces the Discover reading list on the Saved tab.")
    private let bodyText = WMFLocalizedString("discover-announcement-body", value: "Your weekly reading list of Wikipedia articles curated just for you.", comment: "Body of the card that introduces the Discover reading list on the Saved tab.")
    private let getStartedTitle = WMFLocalizedString("discover-announcement-get-started", value: "Get started", comment: "Title of the button on the Discover card that opens the Discover setup.")
    private let noThanksTitle = WMFLocalizedString("discover-announcement-no-thanks", value: "No thanks", comment: "Title of the button on the Discover card that dismisses the card.")

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFDiscoverAnnouncementViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            tag
            Text(title)
                .font(Font(WMFFont.for(.boldCallout)))
                .foregroundColor(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
            Text(bodyText)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .fixedSize(horizontal: false, vertical: true)
            buttons
                .padding(.top, WMFSpacing.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WMFSpacing.large)
        .background(Color(uiColor: theme.midBackground))
        .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge)
                .strokeBorder(Color(uiColor: theme.newBorder), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.announcementCard)
        .onAppear {
            viewModel.viewDidAppear()
        }
    }

    private var tag: some View {
        Text(newTag)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundColor(Color(uiColor: theme.link))
            .padding(.horizontal, WMFSpacing.xSmall)
            .padding(.vertical, WMFSpacing.xxSmall)
            .background(Color(uiColor: theme.softEditorBlue))
            .clipShape(Capsule())
    }

    private var buttons: some View {
        HStack(spacing: WMFSpacing.small) {
            WMFSmallButton(configuration: .init(style: .primary), title: getStartedTitle) {
                viewModel.tapGetStarted()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Discover.announcementGetStartedButton)

            WMFSmallButton(configuration: .init(style: .neutral), title: noThanksTitle) {
                viewModel.tapNoThanks()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Discover.announcementNoThanksButton)
        }
    }
}
