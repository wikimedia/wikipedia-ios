import SwiftUI
import WMFData
import WMFNativeLocalizations

struct WMFDiscoverReadingListRowView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let page: WMFDiscoverRecommendedPage
    let onTap: () -> Void
    let onOpenInNewTab: () -> Void
    let onOpenInBackgroundTab: () -> Void
    let onShare: (CGRect) -> Void

    @State private var thumbnail: UIImage?
    @State private var frame: CGRect = .zero

    private static let thumbnailSize: CGFloat = 98

    private var theme: WMFTheme { appEnvironment.theme }
    private var title: String { page.displayTitle.removingHTML }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: WMFSpacing.medium) {
                VStack(alignment: .leading, spacing: WMFSpacing.xSmall) {
                    Text(title)
                        .font(Font(WMFFont.for(.semiboldHeadline)))
                        .foregroundColor(Color(uiColor: theme.text))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let description = page.description {
                        Text(description)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Self.thumbnailSize, alignment: .topLeading)

                if page.thumbnailURL != nil {
                    thumbnailView
                }
            }
            .padding(.horizontal, WMFSpacing.large)
            .padding(.vertical, WMFSpacing.medium)
            .contentShape(Rectangle())
            .environment(\.layoutDirection, page.project.isRTL ? .rightToLeft : .leftToRight)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel([title, page.description].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .overlay(frameReader)
        .contextMenu {
            Button(action: onTap) {
                Text(CommonStrings.articleTabsOpen)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button(action: onOpenInNewTab) {
                Text(CommonStrings.articleTabsOpenInNewTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIcon) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button(action: onOpenInBackgroundTab) {
                Text(CommonStrings.articleTabsOpenInBackgroundTab)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .tabsIconBackground) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)

            Button {
                onShare(frame)
            } label: {
                Text(CommonStrings.shortShareTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
            }
            .labelStyle(.titleAndIcon)
        }
        .task(id: page.thumbnailURL) {
            thumbnail = nil
            guard let thumbnailURL = page.thumbnailURL else { return }
            thumbnail = await UIImage.loadFaceCropped(from: thumbnailURL)
        }
    }

    private var thumbnailView: some View {
        Color(uiColor: theme.midBackground)
            .overlay {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            .clipShape(RoundedRectangle(cornerRadius: WMFCornerRadius.medium))
    }

    /// Keeps the row's frame for the share popover on iPad.
    private var frameReader: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    frame = geometry.frame(in: .global)
                }
                .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                    frame = newFrame
                }
        }
        .allowsHitTesting(false)
    }
}
