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

            HStack(alignment: .center, spacing: 8) {
                Picker("", selection: $viewModel.selectedTab) {
                    Text(viewModel.communityTabTitle).tag(WMFHomeViewModel.Tab.community)
                    Text(viewModel.forYouTabTitle).tag(WMFHomeViewModel.Tab.forYou)
                }
                .pickerStyle(.segmented)

                Menu {
                    ForEach(viewModel.languages) { language in
                        Button {
                            viewModel.didSelectLanguage?(language)
                        } label: {
                            if language.languageCode == viewModel.selectedLanguage?.languageCode {
                                Label(language.localizedName, systemImage: "checkmark")
                            } else {
                                Text(language.localizedName)
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
                        .foregroundStyle(Color(uiColor: theme.link))
                        .dynamicTypeSize(.xSmall ... .accessibility2)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.Home.languagePickerButton)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    @ViewBuilder
    private var forYouTabContent: some View {
        if let forYouViewModel = viewModel.forYouViewModel {
            WMFForYouView(
                viewModel: forYouViewModel,
                moduleVisibility: viewModel.forYouModuleVisibility,
                hiddenCardKeys: viewModel.hiddenCardKeySet,
                onRefresh: { await viewModel.refreshForYouFeed() },
                onHideModule: { viewModel.hideForYouModule($0) },
                onHideCard: { viewModel.hideForYouCard($0) },
                onCustomizeInterests: { viewModel.didTapCustomizeInterests?() }
            )
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

    @ViewBuilder
    private var communityTabContent: some View {
        if !viewModel.communityPages.isEmpty {
            WMFCommunityFeedView(
                pages: viewModel.communityPages,
                moduleVisibility: viewModel.communityModuleVisibility,
                hiddenCardKeys: viewModel.hiddenCardKeySet,
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
