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
            .task { viewModel.loadCurrentTabFeedIfNeeded() }
            .onChange(of: viewModel.selectedTab) {
                viewModel.loadCurrentTabFeedIfNeeded()
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.selectedTab == .forYou {
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
        } else {
            communitySection
                .environment(\.colorScheme, theme.preferredColorScheme)
        }
    }

    @ViewBuilder
    private var communitySection: some View {
        if #available(iOS 26.0, *) {
            communityTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: [.top, .bottom])
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
            WMFHomeEmbeddedCommunityView(makeViewController: makeEmbeddedViewController)
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
