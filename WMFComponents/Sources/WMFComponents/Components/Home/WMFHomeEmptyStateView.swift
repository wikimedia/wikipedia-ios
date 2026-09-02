import SwiftUI
import WMFNativeLocalizations

/// The empty state of the Home tab. The Community segment and the For You segment both use it.
///
/// The caller gives the palette. The For You segment stays dark when the app uses a light theme.
struct WMFHomeEmptyStateView: View {

    /// The two segments show the same title. This key is already translated, so both segments use it.
    private let title = WMFLocalizedString("for-you-empty-title", value: "Nothing here yet", comment: "Title shown on the Home tab's For You or Community segment when there is no content to display.")

    private let buttonTitle = WMFLocalizedString("home-empty-go-to-settings-button", value: "Go to settings", comment: "Button on the Home tab's For You or Community empty state. It opens the feed settings.")

    let subtitle: String
    let theme: WMFTheme
    let action: () -> Void

    var body: some View {
        let viewModel = WMFEmptyViewModel(
            localizedStrings: WMFEmptyViewModel.LocalizedStrings(
                title: title,
                subtitle: subtitle,
                titleFilter: nil,
                buttonTitle: buttonTitle,
                attributedFilterString: nil
            ),
            image: WMFSFSymbolIcon.for(symbol: .sparkles, font: .xxlTitleBold),
            imageColor: theme.secondaryText,
            numberOfFilters: nil,
            // A nil size keeps the SF Symbol at its natural size. The default size distorts it.
            imageSize: nil
        )

        // Do not use the scrollable variant. It draws its own midBackground. That color is gray700 in
        // the For You palette and shows as a grey panel. This view draws the background and the padding.
        return WMFEmptyView(
            viewModel: viewModel,
            type: .noItems,
            isScrollable: false,
            theme: theme,
            mainAction: action,
            usesCompactButton: true
        )
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
    }
}
