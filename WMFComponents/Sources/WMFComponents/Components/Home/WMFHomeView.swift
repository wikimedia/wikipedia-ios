import SwiftUI
import WMFData

public struct WMFHomeView: View {

    @ObservedObject var viewModel: WMFHomeViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    /// Where the header bar ends, so that a For You card can keep its content below it and Community
    /// can reserve the same space.
    @State private var headerBottom: CGFloat = 0

    /// The scheme Home is placed in. The persistent header falls back to it in the one case that does
    /// not override the scheme itself, which is what that header inherited while it still lived
    /// inside the For You branch.
    @Environment(\.colorScheme) private var inheritedColorScheme

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeViewModel) {
        self.viewModel = viewModel
    }

    private var safeAreaTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top ?? 0
    }


    private static let tabSwitcherCornerRadius: CGFloat = 8

    private var headerBarTopInset: CGFloat { safeAreaTop + 52 }
    private var refreshIndicatorTopInset: CGFloat { headerBarTopInset + 60 }

    private var isForYou: Bool { viewModel.selectedTab == .forYou }

    @ViewBuilder
    private var refreshIndicator: some View {
        if isForYou, viewModel.isRefreshingForYou {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(uiColor: WMFColor.white))
                .padding(10)
                .background(Circle().fill(.ultraThinMaterial))
                .accessibilityLabel(viewModel.forYouRefreshingAccessibilityLabel)
                .transition(.opacity)
        }
    }

    public var body: some View {
        mainContent
            .animation(.easeInOut(duration: 0.2), value: viewModel.isRefreshingForYou)
            .ignoresSafeArea(.keyboard)
            .task { viewModel.loadCurrentTabFeedIfNeeded() }
            .onChange(of: viewModel.selectedTab) {
                viewModel.loadCurrentTabFeedIfNeeded()
            }
    }

    /// The selected feed sits behind one header that outlives it.
    ///
    /// The header, and with it the segmented control, is deliberately outside the `selectedTab`
    /// conditional. While each branch drew its own copy, SwiftUI tore one segmented control down and
    /// built another on every tab change, so on iOS 26 a drag across the segments lost the control
    /// it started on and the header read as if it had been replaced.
    private var mainContent: some View {
        ZStack(alignment: .top) {
            feedContent
            homeHeader
            refreshIndicator
                .padding(.top, refreshIndicatorTopInset)
        }
        // Only the top edge: the header is placed from the top of the screen, while each feed opts
        // into a full-bleed bottom itself. Community thus keeps the bottom safe area it laid out
        // against before the header moved out of it.
        .ignoresSafeArea(.container, edges: .top)
        .onPreferenceChange(WMFForYouHeaderBottomKey.self) { headerBottom = $0 }
    }

    @ViewBuilder
    private var feedContent: some View {
        if isForYou {
            forYouTabContent
                .ignoresSafeArea()
                .environment(\.forYouHeaderBottom, headerBottom)
                .environment(\.colorScheme, .dark)
        } else {
            communitySection
                .environment(\.colorScheme, theme.preferredColorScheme)
        }
    }

    // MARK: - Persistent header

    /// One header for the lifetime of the view. Everything that differs between the feeds is a value
    /// this reads, never a branch around the header, so the segmented control keeps its identity.
    private var homeHeader: some View {
        headerBar
            .environment(\.colorScheme, headerColorScheme)
            .padding(.top, headerBarTopInset)
            .background(headerBackground)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: WMFForYouHeaderBottomKey.self,
                        value: proxy.frame(in: .global).maxY
                    )
                }
            }
    }

    /// The header takes the scheme of the feed behind it, the way each feed's own copy used to.
    private var headerColorScheme: ColorScheme {
        guard isForYou else { return theme.preferredColorScheme }
        if #available(iOS 26.0, *) {
            return inheritedColorScheme
        }
        return .dark
    }

    /// iOS 26 lets both feeds show through the header's glass chrome. Older iOS keeps Community
    /// opaque, so a feed passing under the header reads the way the in-flow header used to.
    private var headerBackground: Color {
        if #available(iOS 26.0, *) {
            return .clear
        }
        return isForYou ? .clear : Color(uiColor: theme.paperBackground)
    }

    /// The space Community reserves for the header floating over it.
    private var communityHeaderInset: CGFloat {
        WMFHomeHeaderMetrics.communityTopInset(
            measuredHeaderBottom: headerBottom,
            headerTopInset: headerBarTopInset
        )
    }

    @ViewBuilder
    private var communitySection: some View {
        if #available(iOS 26.0, *) {
            communityTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: [.top, .bottom])
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: communityHeaderInset)
                }
                .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
        } else {
            VStack(spacing: 0) {
                Color.clear.frame(height: communityHeaderInset)
                communityTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.paperBackground))
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $viewModel.selectedTab) {
                Text(viewModel.communityTabTitle).tag(WMFHomeViewModel.Tab.community)
                Text(viewModel.forYouTabTitle).tag(WMFHomeViewModel.Tab.forYou)
            }
            .padding(.vertical, 2)
            .pickerStyle(.segmented)
            .fixedSize()
            .modifier(WMFGlassEffectModifier())
            
            Spacer()
            
            if viewModel.shouldShowLanguagePicker {
                Menu {
                    ForEach(viewModel.languages) { language in
                        Button {
                            if language.languageCode != viewModel.selectedLanguage?.languageCode {
                                viewModel.logDidTapLanguagePicker?(language.languageCode)
                            }
                            viewModel.didSelectLanguage?(language)
                        } label: {
                            if language.languageCode == viewModel.selectedLanguage?.languageCode {
                                Label {
                                    Text(language.localizedName)
                                } icon: {
                                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .checkmark) ?? UIImage())
                                }
                                .minimumScaleFactor(0.25)
                            } else {
                                Text(language.localizedName)
                                    .minimumScaleFactor(0.25)
                            }
                        }
                        .tint(.primary)
                    }
                    Divider()
                    Button {
                        viewModel.didTapEditLanguages?()
                    } label: {
                        Label {
                            Text(viewModel.editLanguagesTitle)
                        } icon: {
                            Image(uiImage: WMFSFSymbolIcon.for(symbol: .globe) ?? UIImage())
                        }
                    }
                    .tint(.primary)
                } label: {
                    HStack {
                        Text(viewModel.languageButtonTitle)
                            .font(Font(WMFFont.for(.semiboldSubheadline)))
                            .dynamicTypeSize(.xSmall ... .large)
                            .minimumScaleFactor(0.25)
                            .foregroundStyle(languageButtonForeground)
                            .lineLimit(1)
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronUpChevronDown, font: .boldCaption1, compatibleWith: .wmfCappedForSFSymbols) ?? UIImage())
                            .foregroundStyle(languageButtonForeground)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .modifier(WMFLanguageButtonContainerModifier())
                .accessibilityIdentifier(AccessibilityIdentifiers.Home.languagePickerButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private var languageButtonForeground: Color {
        if #available(iOS 26.0, *) {
            return .primary
        }
        return isForYou ? Color(uiColor: WMFColor.white) : Color(uiColor: theme.text)
    }

    // MARK: - For You Tab

    @ViewBuilder
    private var forYouTabContent: some View {
        if let forYouViewModel = viewModel.forYouViewModel {
            WMFForYouView(viewModel: forYouViewModel, scrollToTopRequestID: viewModel.forYouScrollToTopRequestID)
                .ignoresSafeArea()
        } else if viewModel.isLoadingForYou {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.forYouFeedError != nil {
            let errorViewModel = WMFEmptyViewModel(
                localizedStrings: WMFEmptyViewModel.LocalizedStrings(
                    title: viewModel.forYouErrorTitle,
                    subtitle: viewModel.forYouErrorSubtitle,
                    titleFilter: nil,
                    buttonTitle: viewModel.forYouErrorRetryTitle,
                    attributedFilterString: nil
                ),
                image: nil,
                imageColor: nil,
                numberOfFilters: nil
            )

            WMFEmptyView(
                viewModel: errorViewModel,
                type: .noItems,
                isScrollable: false,
                theme: .forYou,
                mainAction: { viewModel.loadForYouFeedIfNeeded() },
                usesCompactButton: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: WMFTheme.forYou.paperBackground))
        } else {
            Text(viewModel.forYouTabTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: WMFTheme.forYou.secondaryText))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Community Tab

    @ViewBuilder
    private var communityTabContent: some View {
        if let makeEmbeddedViewController = viewModel.makeEmbeddedCommunityViewController {
            if viewModel.isEmbeddedCommunityFeedEmpty {
                embeddedCommunityEmptyView
            } else {
                WMFHomeEmbeddedCommunityView(makeViewController: makeEmbeddedViewController)
            }
        } else if !viewModel.communityPages.isEmpty {
            WMFCommunityFeedView(
                pages: viewModel.communityPages,
                moduleVisibility: viewModel.communityModuleVisibility,
                hiddenCardKeys: viewModel.hiddenCardKeys,
                isLoadingPreviousPage: viewModel.isLoadingCommunityPreviousPage,
                onHideModule: { viewModel.hideModule($0) },
                onHideCard: { viewModel.hideCard(key: $0) },
                onRefresh: { await viewModel.refreshCommunityFeed() },
                onTapSeePastContent: { viewModel.loadCommunityPreviousPage() },
                scrollToTopRequestID: viewModel.communityScrollToTopRequestID
            )
        } else if viewModel.isLoadingCommunity {
            Spacer()
            ProgressView()
            Spacer()
        } else {
            Spacer()
            Text(viewModel.communityTabTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            Spacer()
        }
    }

    /// Replaces the embedded feed when all the Community cards are hidden.
    ///
    /// The embedded view controller does not show this. Auto Layout content in its root view gives the
    /// root a fitting size, and SwiftUI then makes the embedded feed as small as that size.
    private var embeddedCommunityEmptyView: some View {
        WMFHomeEmptyStateView(
            subtitle: viewModel.communityEmptyFeedSubtitle,
            theme: theme,
            action: { viewModel.didTapCustomizeCommunityFeed?() }
        )
    }
}

/// Supplies the material behind the segmented control.
///
/// The iOS 26 segmented control does not bring Liquid Glass of its own here: left alone it draws a
/// flat, nearly transparent track that shows the feed straight through it and all but disappears
/// over the dark For You background. So the glass is applied explicitly, and `HomeViewController`
/// clears the control's own track so this stays the single material rather than a second one.
private struct WMFGlassEffectModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect()
        } else {
            content.background(RoundedRectangle(cornerRadius: 9).fill(.ultraThinMaterial))
        }
    }
}

private struct WMFLanguageButtonContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tint(.primary)
                .glassEffect()
        } else {
            content
                .background(Capsule().fill(.ultraThinMaterial))
        }
    }
}

/// Layout math for the persistent Home header, kept beside the view so it can be exercised directly.
enum WMFHomeHeaderMetrics {

    /// The space Community reserves at its top for the header floating over it.
    ///
    /// `measuredHeaderBottom` is the header's bottom edge in window coordinates, which is where
    /// Community's resting content belongs. It reads zero until the first measurement lands, so the
    /// header's own top inset acts as a floor and keeps that first pass from starting content
    /// underneath the header.
    static func communityTopInset(measuredHeaderBottom: CGFloat, headerTopInset: CGFloat) -> CGFloat {
        max(measuredHeaderBottom, headerTopInset)
    }
}
