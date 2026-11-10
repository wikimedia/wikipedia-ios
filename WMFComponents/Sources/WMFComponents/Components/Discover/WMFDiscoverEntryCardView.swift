import SwiftUI
import WMFNativeLocalizations

/// The pinned Discover card at the top of the Saved tab: the title with a dot while the list is
/// unseen, the byline, the cadence description and a two by two collage of the list's images.
public struct WMFDiscoverEntryCardView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDiscoverEntryCardViewModel

    private static let bylineFormat = WMFLocalizedString("discover-entry-card-byline", value: "Made for %1$@", comment: "Byline on the Discover card at the top of the Saved tab. %1$@ is replaced with the account name of the reader or the word for 'you'.")
    private static let unseenListAccessibilityLabel = WMFLocalizedString("discover-entry-card-unseen-list", value: "New list", comment: "Accessibility label of the dot on the Discover card at the top of the Saved tab. The dot marks a list the reader has not opened yet.")

    private static let collageWidth: CGFloat = 128
    private static let unseenDotSize: CGFloat = 8

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    public init(viewModel: WMFDiscoverEntryCardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button {
            viewModel.tapCard()
        } label: {
            HStack(alignment: .top, spacing: WMFSpacing.large) {
                textColumn
                collage
            }
            .padding(WMFSpacing.large)
        }
        .buttonStyle(WMFDiscoverEntryCardButtonStyle(theme: theme))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.entryCard)
        .onAppear {
            viewModel.viewDidAppear()
        }
    }

    private var textColumn: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            HStack(spacing: WMFSpacing.xSmall) {
                Text(WMFDiscoverReadingListView.title)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(uiColor: theme.text))
                if viewModel.hasUnseenList {
                    Circle()
                        .fill(Color(uiColor: theme.destructive))
                        .frame(width: Self.unseenDotSize, height: Self.unseenDotSize)
                        .accessibilityLabel(Self.unseenListAccessibilityLabel)
                }
            }
            byline
            Text(viewModel.descriptionText)
                .font(Font(WMFFont.for(.footnote)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var byline: some View {
        HStack(spacing: WMFSpacing.xSmall) {
            Image(uiImage: WMFIcon.wikipediaW ?? UIImage())
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 14)
                .accessibilityHidden(true)
            bylineText
        }
        .font(Font(WMFFont.for(.footnote)))
        .foregroundColor(Color(uiColor: theme.text))
    }

    private var bylineText: Text {
        let name = viewModel.username ?? WMFDiscoverReadingListView.bylineYou
        var byline = AttributedString(String.localizedStringWithFormat(Self.bylineFormat, name))
        if viewModel.username != nil, let nameRange = byline.range(of: name) {
            byline[nameRange].font = Font(WMFFont.for(.boldFootnote))
        }
        return Text(byline)
    }

    private var collage: some View {
        WMFImageCollageView(viewModel: viewModel.collageViewModel)
            .frame(width: Self.collageWidth)
            .overlay {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(Color(uiColor: theme.secondaryText))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.medium))
    }
}

/// Paints the card. A pressed card darkens its background and keeps its content at full opacity.
private struct WMFDiscoverEntryCardButtonStyle: ButtonStyle {

    let theme: WMFTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: configuration.isPressed ? theme.baseBackground : theme.midBackground))
            .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge))
            .overlay(
                RoundedRectangle(cornerRadius: WMFCornerRadius.xLarge)
                    .strokeBorder(Color(uiColor: theme.newBorder), lineWidth: 1)
            )
    }
}
