import SwiftUI
import WMFData
import WMFNativeLocalizations

public struct WMFDiscoverReadingListView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFDiscoverReadingListViewModel

    @StateObject private var menuButtonHandler: WMFDiscoverMenuButtonHandler

    static let title = WMFLocalizedString("discover-list-title", value: "Discover", comment: "Title of the Discover reading list screen.")
    private static let errorTitle = WMFLocalizedString("discover-list-error-title", value: "Network error", comment: "Title of the error view on the Discover reading list screen when the list cannot be loaded.")
    private static let errorSubtitle = WMFLocalizedString("discover-list-error-subtitle", value: "Unable to load reading list.", comment: "Subtitle of the error view on the Discover reading list screen when the list cannot be loaded.")
    private static let emptyMessage = WMFLocalizedString("discover-list-empty-message", value: "Unfortunately there are no recommendations for you at this time.", comment: "Message shown on the Discover reading list screen when the app has no articles to recommend.")
    private static let bylineFormat = WMFLocalizedString("discover-list-byline", value: "Made for %1$@ • %2$@", comment: "Byline under the title of the Discover reading list. %1$@ is replaced with the account name of the reader or the word for 'you', %2$@ with the number of articles in the list.")
    private static let bylineYou = WMFLocalizedString("discover-list-byline-you", value: "you", comment: "Word used in the Discover reading list byline in place of the account name when the reader is logged out. Appears as 'Made for you'.")
    private static let saveListTitle = WMFLocalizedString("discover-list-save-list", value: "Save list", comment: "Button on the Discover reading list screen that saves every article in the list to a reading list.")
    private static let aboutTitle = WMFLocalizedString("discover-list-about", value: "About this feature", comment: "Menu item on the Discover reading list screen that explains how Discover works.")

    @MainActor fileprivate static let customizeMenuItem = WMFSmallMenuButton.MenuItem(
        title: WMFDiscoverReadingListViewModel.customizeTitle,
        image: WMFSFSymbolIcon.for(symbol: .sliderHorizontal3)
    )
    @MainActor fileprivate static let shareMenuItem = WMFSmallMenuButton.MenuItem(
        title: CommonStrings.shortShareTitle,
        image: WMFSFSymbolIcon.for(symbol: .squareAndArrowUp)
    )
    @MainActor fileprivate static let aboutMenuItem = WMFSmallMenuButton.MenuItem(
        title: aboutTitle,
        image: WMFSFSymbolIcon.for(symbol: .infoCircle)
    )

    private var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFDiscoverReadingListViewModel) {
        self.viewModel = viewModel
        _menuButtonHandler = StateObject(wrappedValue: WMFDiscoverMenuButtonHandler(viewModel: viewModel))
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.paperBackground)
                .ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
            case .error:
                errorView
            case .loaded, .empty:
                listView
            }
        }
    }

    // MARK: - States

    private var errorView: some View {
        let errorViewModel = WMFErrorViewModel(
            localizedStrings: WMFErrorViewModel.LocalizedStrings(
                title: Self.errorTitle,
                subtitle: Self.errorSubtitle,
                buttonTitle: CommonStrings.retryActionTitle
            ),
            image: WMFIcon.error
        )
        return WMFErrorView(viewModel: errorViewModel) {
            viewModel.load()
        }
    }

    /// The empty state fills the visible height so the illustration sits below the header without a scroll.
    private var listView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    WMFImageCollageView(viewModel: viewModel.collageViewModel)

                    VStack(spacing: 0) {
                        header
                        if viewModel.pages.isEmpty {
                            emptyView
                        } else {
                            rows
                        }
                    }
                    .readableWidth()
                }
                .frame(minHeight: viewModel.pages.isEmpty ? geometry.size.height + geometry.safeAreaInsets.top : nil)
            }
            .ignoresSafeArea(edges: .top)
            .hidingTopScrollEdgeEffect()
        }
    }

    private var rows: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.pages) { page in
                WMFDiscoverReadingListRowView(
                    page: page,
                    onTap: { viewModel.tapArticle(page) },
                    onOpenInNewTab: { viewModel.tapOpenInNewTab(page) },
                    onOpenInBackgroundTab: { viewModel.tapOpenInBackgroundTab(page) },
                    onShare: { sourceRect in viewModel.tapShareArticle(page, sourceRect: sourceRect) }
                )
                Divider()
                    .overlay(Color(uiColor: theme.newBorder))
                    .padding(.leading, WMFSpacing.large)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: WMFSpacing.xLarge) {
            Image("discover-empty-state", bundle: .module)
                .accessibilityHidden(true)
            Text(Self.emptyMessage)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, WMFSpacing.large)
        .padding(.bottom, WMFSpacing.large)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: WMFSpacing.small) {
            Text(Self.title)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundColor(Color(uiColor: theme.text))

            byline

            if !viewModel.pages.isEmpty {
                Text(viewModel.descriptionText)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }

            HStack(spacing: WMFSpacing.small) {
                saveListButton
                moreMenu
            }
            .padding(.top, WMFSpacing.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WMFSpacing.large)
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
        .foregroundColor(Color(uiColor: theme.secondaryText))
    }

    private var bylineText: Text {
        let name = viewModel.username ?? Self.bylineYou
        var byline = AttributedString(String.localizedStringWithFormat(Self.bylineFormat, name, viewModel.articleCountText))
        if viewModel.username != nil, let nameRange = byline.range(of: name) {
            byline[nameRange].font = Font(WMFFont.for(.boldFootnote))
        }
        return Text(byline)
    }

    // MARK: - Buttons

    private var saveListButton: some View {
        Button {
            viewModel.tapSaveList()
        } label: {
            HStack(spacing: WMFSpacing.xSmall) {
                if let icon = WMFSFSymbolIcon.for(symbol: .bookmark, font: .semiboldSubheadline) {
                    Image(uiImage: icon)
                }
                Text(Self.saveListTitle)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
            }
            .padding(.horizontal, WMFSpacing.medium)
        }
        .buttonStyle(
            CapsuleButtonStyle(
                kind: .neutral,
                layout: .hug,
                theme: theme,
                height: 32,
                forceForegroundColor: viewModel.pages.isEmpty ? theme.secondaryText : nil
            )
        )
        .disabled(viewModel.pages.isEmpty)
    }

    private var moreMenu: some View {
        WMFSmallSwiftUIMenuButton(
            configuration: WMFSmallMenuButton.Configuration(
                image: WMFSFSymbolIcon.for(symbol: .ellipsis, font: .semiboldSubheadline),
                primaryColor: \.link,
                menuItems: menuItems
            ),
            menuButtonDelegate: menuButtonHandler
        )
        .accessibilityLabel(CommonStrings.moreButton)
        .overlay(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        menuButtonHandler.moreButtonFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        menuButtonHandler.moreButtonFrame = newFrame
                    }
            }
            .allowsHitTesting(false)
        )
    }

    /// Share needs articles to share. The other items depend on the screens the coordinator wires up.
    private var menuItems: [WMFSmallMenuButton.MenuItem] {
        var items: [WMFSmallMenuButton.MenuItem] = []
        if viewModel.didTapCustomize != nil {
            items.append(Self.customizeMenuItem)
        }
        if !viewModel.pages.isEmpty {
            items.append(Self.shareMenuItem)
        }
        if viewModel.didTapAbout != nil {
            items.append(Self.aboutMenuItem)
        }
        return items
    }
}

private extension View {
    /// iOS 26 paints a scroll edge effect under the transparent bar. On the iPhone Duo the effect is opaque and hides the collage.
    @ViewBuilder
    func hidingTopScrollEdgeEffect() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(true, for: .top)
        } else {
            self
        }
    }
}

/// Routes the taps of the shared menu button to the view model. The share item needs the button frame for the iPad popover.
@MainActor
private final class WMFDiscoverMenuButtonHandler: ObservableObject, WMFSmallMenuButtonDelegate {

    private weak var viewModel: WMFDiscoverReadingListViewModel?
    var moreButtonFrame: CGRect = .zero

    init(viewModel: WMFDiscoverReadingListViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func wmfSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {
        MainActor.assumeIsolated {
            handle(item)
        }
    }

    nonisolated func wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {
        MainActor.assumeIsolated {
            handle(item)
        }
    }

    private func handle(_ item: WMFSmallMenuButton.MenuItem?) {
        guard let item, let viewModel else { return }
        switch item {
        case WMFDiscoverReadingListView.customizeMenuItem:
            viewModel.didTapCustomize?()
        case WMFDiscoverReadingListView.shareMenuItem:
            viewModel.tapShareList(sourceRect: moreButtonFrame)
        case WMFDiscoverReadingListView.aboutMenuItem:
            viewModel.didTapAbout?()
        default:
            break
        }
    }
}
