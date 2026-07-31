import SwiftUI
import WMFData

public struct WMFHomeView: View {

    @ObservedObject var viewModel: WMFHomeViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

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

    public var body: some View {
        mainContent
            .task { viewModel.loadCurrentTabFeedIfNeeded() }
            .onChange(of: viewModel.selectedTab) { _ in
                viewModel.loadCurrentTabFeedIfNeeded()
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.selectedTab == .forYou {
            ZStack(alignment: .top) {
                forYouTabContent
                    .ignoresSafeArea()
                headerBar
                    .padding(.top, safeAreaTop + 52)
            }
            .ignoresSafeArea()
            .environment(\.colorScheme, .dark)
        } else {
            communitySection
        }
    }
    
    @ViewBuilder
    private var communitySection: some View {
        if #available(iOS 26.0, *) {
            communityTabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .top)
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerBar
                }
        } else {
            VStack(spacing: 0) {
                headerBar
                communityTabContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.paperBackground))
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                tabButton(title: viewModel.communityTabTitle, tab: .community)
                tabButton(title: viewModel.forYouTabTitle, tab: .forYou)
            }
            .padding(3)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule().fill(.clear).glassEffect(in: Capsule())
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .dynamicTypeSize(.xSmall ... .large)

            Spacer()

            if viewModel.shouldShowLanguagePicker {
                Menu {
                    ForEach(viewModel.languages) { language in
                        Button {
                            viewModel.didSelectLanguage?(language)
                        } label: {
                            if language.languageCode == viewModel.selectedLanguage?.languageCode {
                                Label(language.localizedName, systemImage: "checkmark")
                                    .minimumScaleFactor(0.25)
                            } else {
                                Text(language.localizedName)
                                    .minimumScaleFactor(0.25)
                            }
                        }
                    }
                    Divider()
                    Button {
                        viewModel.didTapEditLanguages?()
                    } label: {
                        Label(viewModel.editLanguagesTitle, systemImage: "globe")
                    }
                } label: {
                    Text(viewModel.languageButtonTitle)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .dynamicTypeSize(.xSmall ... .large)
                        .minimumScaleFactor(0.25)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if #available(iOS 26.0, *) {
                        Capsule().fill(.clear).glassEffect(in: Capsule())
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                    }
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Home.languagePickerButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }


    private func tabButton(title: String, tab: WMFHomeViewModel.Tab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedTab = tab
            }
        } label: {
            Text(title)
                .font(Font(WMFFont.for(.semiboldSubheadline)))
                .minimumScaleFactor(0.25)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        if #available(iOS 26.0, *) {
                            Capsule().fill(.clear).glassEffect(.regular.interactive(), in: Capsule())
                        } else {
                        
                        }
                    }
                }
        }
    }

    // MARK: - For You Tab

    @ViewBuilder
    private var forYouTabContent: some View {
        if let forYouViewModel = viewModel.forYouViewModel {
            WMFForYouView(viewModel: forYouViewModel)
                .ignoresSafeArea()
        } else if viewModel.isLoadingForYou {
            Spacer()
            ProgressView()
            Spacer()
        } else if viewModel.forYouFeedError != nil {
            VStack(spacing: 16) {
                Spacer()
                Text(viewModel.forYouErrorTitle)
                    .font(Font(WMFFont.for(.boldHeadline)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .multilineTextAlignment(.center)
                Text(viewModel.forYouErrorSubtitle)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button {
                    viewModel.loadForYouFeedIfNeeded()
                } label: {
                    Text(viewModel.forYouErrorRetryTitle)
                        .font(Font(WMFFont.for(.boldCallout)))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: theme.link), in: Capsule())
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .padding(.top, safeAreaTop + 52)
        } else {
            Spacer()
            Text(viewModel.forYouTabTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            Spacer()
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
                onTapSeePastContent: { viewModel.loadCommunityPreviousPage() }
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
