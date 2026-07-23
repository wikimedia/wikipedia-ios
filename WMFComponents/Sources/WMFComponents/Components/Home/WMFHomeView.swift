import SwiftUI
import WMFData

public struct WMFHomeView: View {

    @ObservedObject var viewModel: WMFHomeViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeViewModel) {
        self.viewModel = viewModel
    }

    private var navBarBottom: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = scene?.windows.first
        let safeAreaTop = window?.safeAreaInsets.top ?? 0
        return safeAreaTop + 44
    }

    private var navTheme: WMFTheme {
        viewModel.selectedTab == .forYou ? .dark : theme
    }

    private var isLandscape: Bool {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.interfaceOrientation.isLandscape ?? false
    }

    private var horizontalPadding: CGFloat {
        isLandscape ? 120 : 16
    }

    public var body: some View {
        ZStack(alignment: .top) {
            if viewModel.selectedTab == .forYou {
                forYouTabContent
            } else {
                communityTabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: theme.paperBackground))
                    .padding(.top, navBarBottom + 52)
            }

            HStack(spacing: 8) {
                WMFForYouTabPicker(
                    selectedTab: $viewModel.selectedTab,
                    communityTitle: viewModel.communityTabTitle,
                    forYouTitle: viewModel.forYouTabTitle,
                    theme: navTheme
                )

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
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .foregroundStyle(Color(uiColor: navTheme.text))
                            .dynamicTypeSize(.xSmall ... .accessibility2)
                            .minimumScaleFactor(0.25)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(uiColor: navTheme.text))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: navTheme.baseBackground), in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityIdentifier(AccessibilityIdentifiers.Home.languagePickerButton)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)
            .padding(.top, navBarBottom + 8)
            .background(viewModel.selectedTab == .forYou ? Color.clear : Color(uiColor: theme.paperBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .environment(\.colorScheme, theme.preferredColorScheme)
        .task {
            viewModel.loadCurrentTabFeedIfNeeded()
        }
        .onChange(of: viewModel.selectedTab) {
            viewModel.loadCurrentTabFeedIfNeeded()
        }
    }

    // MARK: - Tab Picker

    private struct WMFForYouTabPicker: View {
        @Binding var selectedTab: WMFHomeViewModel.Tab
        let communityTitle: String
        let forYouTitle: String
        let theme: WMFTheme

        var body: some View {
            HStack(spacing: 2) {
                tabButton(title: communityTitle, tab: .community)
                tabButton(title: forYouTitle, tab: .forYou)
            }
            .padding(3)
            .background(Color(uiColor: theme.baseBackground), in: Capsule())
            .dynamicTypeSize(.xSmall ... .large)
        }

        private func tabButton(title: String, tab: WMFHomeViewModel.Tab) -> some View {
            let isSelected = selectedTab == tab
            return Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            } label: {
                Text(title)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundStyle(isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.text))
                    .minimumScaleFactor(0.25)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(Color(uiColor: theme.midBackground))
                            }
                        }
                    )
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
