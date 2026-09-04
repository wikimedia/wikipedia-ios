import SwiftUI
import WMFData

public struct WMFHomeView: View {

    @ObservedObject var viewModel: WMFHomeViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    /// Where the header bar ends, so that a For You card can keep its content below it.
    @State private var headerBottom: CGFloat = 0

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

    @ViewBuilder
    private var refreshIndicator: some View {
        if viewModel.isRefreshingForYou {
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

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.selectedTab == .forYou {
            if let forYouViewModel = viewModel.forYouViewModel {
                WMFHomeForYouSection(forYouViewModel: forYouViewModel) {
                    forYouFeedContent
                } emptyState: {
                    forYouEmptyFeedContent(forYouViewModel: forYouViewModel)
                }
            } else {
                // Loading, error, and placeholder: there is no feed view model yet.
                forYouStateChrome {
                    forYouTabContent
                }
            }
        } else {
            communitySection
                .environment(\.colorScheme, theme.preferredColorScheme)
        }
    }

    // MARK: - For You Tab: containers

    /// The feed, drawn under every edge, with the header floating over the cards.
    private var forYouFeedContent: some View {
        ZStack(alignment: .top) {
            forYouTabContent
                .ignoresSafeArea()
                .environment(\.forYouHeaderBottom, headerBottom)
                .environment(\.colorScheme, .dark)
            headerBar(isForYou: true)
                .modifier(WMFLegacyDarkHeaderModifier())
                .padding(.top, headerBarTopInset)
                .background {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: WMFForYouHeaderBottomKey.self,
                            value: proxy.frame(in: .global).maxY
                        )
                    }
                }
            refreshIndicator
                .padding(.top, refreshIndicatorTopInset)
        }
        .ignoresSafeArea()
        .onPreferenceChange(WMFForYouHeaderBottomKey.self) { headerBottom = $0 }
    }

    /// The chrome shared by every non-feed state of the For You tab: loading, error, placeholder,
    /// and the all-modules-hidden empty state.
    ///
    /// Like the Community empty state, these respect the safe areas: they end with a button, and
    /// under an ignored bottom edge the button could never scroll clear of the tab bar. Only the
    /// background draws under the edges. The header comes in as a safe area inset, the way the
    /// Community section places it, rather than with the feed's manual inset.
    private func forYouStateChrome<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                headerBar(isForYou: true)
                    .modifier(WMFLegacyDarkHeaderModifier())
            }
            .background(Color(uiColor: WMFTheme.forYou.paperBackground).ignoresSafeArea())
            .environment(\.colorScheme, .dark)
    }

    /// The empty state for a feed whose modules are all off or hidden. It lived inside
    /// `WMFForYouView` before; it sits here now so every empty state of the tab shares
    /// `forYouStateChrome` and none of them ends up under the tab bar.
    private func forYouEmptyFeedContent(forYouViewModel: WMFForYouViewModel) -> some View {
        forYouStateChrome {
            WMFHomeEmptyStateView(
                subtitle: forYouViewModel.emptySubtitle,
                theme: .forYou,
                action: { forYouViewModel.onCustomizeInterests?(.emptyFeed) }
            )
            .onAppear {
                forYouViewModel.onEmptyViewAppearance?()
            }
        }
    }

    /// The edges the Community section draws under. The feed draws under the tab bar for the
    /// full-bleed reading experience, but the empty state respects every edge: it ends with the
    /// customize button, and under an ignored edge the button can never scroll clear of the bar.
    private var communityIgnoredSafeAreaEdges: Edge.Set {
        viewModel.isEmbeddedCommunityFeedEmpty ? [] : [.top, .bottom]
    }

    @ViewBuilder
    private var communitySection: some View {
        if #available(iOS 26.0, *) {
            communityTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: communityIgnoredSafeAreaEdges)
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerBar(isForYou: false)
                }
                .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
        } else {
            VStack(spacing: 0) {
                headerBar(isForYou: false)
                communityTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.paperBackground))
        }
    }
    
    private func headerBar(isForYou: Bool) -> some View {
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
                            .foregroundStyle(languageButtonForeground(isForYou: isForYou))
                            .lineLimit(1)
                        Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronUpChevronDown, font: .boldCaption1, compatibleWith: .wmfCappedForSFSymbols) ?? UIImage())
                            .foregroundStyle(languageButtonForeground(isForYou: isForYou))
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

    private func languageButtonForeground(isForYou: Bool) -> Color {
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

/// Chooses between the For You feed and its empty state.
///
/// A view of its own because the choice depends on `WMFForYouViewModel`, which `WMFHomeView` does
/// not observe: `WMFHomeView` observes only the home view model, so without this wrapper, hiding
/// the last card would not swap the feed for the empty state until something else redrew the
/// screen.
private struct WMFHomeForYouSection<Feed: View, EmptyState: View>: View {
    @ObservedObject var forYouViewModel: WMFForYouViewModel
    @ViewBuilder let feed: () -> Feed
    @ViewBuilder let emptyState: () -> EmptyState

    var body: some View {
        if forYouViewModel.isFeedEmpty {
            emptyState()
        } else {
            feed()
        }
    }
}

private struct WMFLegacyDarkHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content.environment(\.colorScheme, .dark)
        }
    }
}

private struct WMFGlassEffectModifier: ViewModifier {
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
