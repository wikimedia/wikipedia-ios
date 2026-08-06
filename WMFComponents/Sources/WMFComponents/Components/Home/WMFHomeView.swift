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
                headerBar(isForYou: true)
                    .padding(.top, safeAreaTop + 52)
            }
            .ignoresSafeArea()
            .environment(\.colorScheme, .dark)
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
            .dynamicTypeSize(.xSmall ... .large)
            .background {
                if #available(iOS 26.0, *) {
                    Capsule().fill(.clear).glassEffect(in: Capsule())
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }

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
                        .foregroundStyle(isForYou ? .white : .primary)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isForYou ? .white : .primary)
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

    // MARK: - For You Tab

    @ViewBuilder
    private var forYouTabContent: some View {
        if let forYouViewModel = viewModel.forYouViewModel {
            WMFForYouView(viewModel: forYouViewModel)
                .ignoresSafeArea()
        } else if viewModel.isLoadingForYou {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Text(viewModel.forYouTabTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
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
