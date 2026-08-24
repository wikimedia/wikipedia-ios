import SwiftUI
import WMFNativeLocalizations

/// The Home tab's empty state, shared by both segments so they stay identical in everything but their
/// copy and where their button leads.
///
/// The palette is passed in rather than read from the environment: For You stays dark whatever theme
/// the app is set to, while Community follows the app.
struct WMFHomeEmptyStateView: View {

    /// Both segments show the same title, so it stays here on the shared view — and keeps the key the
    /// For You empty state already ships translated rather than duplicating the English under a new one.
    private let title = WMFLocalizedString("for-you-empty-title", value: "Nothing here yet", comment: "Title shown on the Home tab's For You or Community segment when there is no content to display.")

    /// Both segments send the reader to settings, so the button title is shared too. Only the subtitle
    /// and the destination differ between them.
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
            // nil keeps the SF Symbol at its natural size — the illustration frame distorts it.
            imageSize: nil
        )

        // Not the scrollable variant: it paints its own midBackground, which is gray700 on the For You
        // palette and would show as a grey panel behind that feed. The padding it would have added
        // comes from here instead, so the text keeps a readable measure.
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
