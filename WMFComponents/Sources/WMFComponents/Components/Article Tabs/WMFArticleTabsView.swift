import SwiftUI
import WMFData

@available(iOS 16.4, *) // Note: the app is currently 16.6+, but the package config doesn't allow minor version configs
public struct WMFArticleTabsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) var colorScheme

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFArticleTabsViewModel
    /// Flag to allow us to know if we can scroll to the current tab position
    @State private var isReady: Bool = false
    @State private var currentTabID: String?

    public init(viewModel: WMFArticleTabsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                if !isReady {
                    loadingView
                } else if viewModel.articleTabs.isEmpty {
                    emptyStateContainer
                } else {
                    tabsGrid(geometry)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(theme.midBackground))
        }
        .onReceive(viewModel.$articleTabs) { tabs in
            guard !isReady else { return }

            if tabs.isEmpty {
                isReady = true
            } else {
                Task {
                    if let tab = await viewModel.getCurrentTab() {
                        currentTabID = tab.id
                    }
                    isReady = true
                }
            }
        }
        .background(Color(theme.midBackground))
        .toolbarBackground(Color(theme.midBackground), for: .automatic)
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateContainer: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: true) {
                VStack {
                    let locStrings = WMFEmptyViewModel.LocalizedStrings(
                        title: viewModel.localizedStrings.emptyStateTitle,
                        subtitle: viewModel.localizedStrings.emptyStateSubtitle,
                        titleFilter: nil,
                        buttonTitle: nil,
                        attributedFilterString: nil
                    )
                    let emptyViewModel = WMFEmptyViewModel(
                        localizedStrings: locStrings,
                        image: UIImage(named: "empty-tabs", in: .module, with: nil),
                        imageColor: nil,
                        numberOfFilters: 0
                    )
                    WMFEmptyView(viewModel: emptyViewModel, type: .noItems)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            }
            .background(Color(theme.paperBackground))
            .scrollBounceBehavior(.always)
        }
    }

    // MARK: - Grid

    private func tabsGrid(_ geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: viewModel.calculateColumns(for: geometry.size))) {
                    ForEach(viewModel.articleTabs.sorted(by: { $0.dateCreated < $1.dateCreated }), id: \.id) { tab in
                        WMFArticleTabsViewContent(viewModel: viewModel, tab: tab)
                            .id(tab.id)
                            .accessibilityActions {
                                accessibilityAction(named: viewModel.localizedStrings.openTabAccessibility) {
                                    viewModel.didTapTab(tab.data)
                                }

                                if viewModel.shouldShowCloseButton {
                                    accessibilityAction(named: viewModel.localizedStrings.closeTabAccessibility) {
                                        viewModel.closeTab(tab: tab)
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .onAppear {
                    Task {
                        await Task.yield()
                        if let id = currentTabID {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tab content

fileprivate struct WMFArticleTabsViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject var viewModel: WMFArticleTabsViewModel
    @ObservedObject var tab: ArticleTab

    public init(viewModel: WMFArticleTabsViewModel, tab: ArticleTab) {
        self.viewModel = viewModel
        self.tab = tab
    }

    public var body: some View {
        Group {
            if tab.isMain {
                mainPageTabContent()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(viewModel.getAccessibilityLabel(for: tab))
            } else {
                if tab.info == nil {
                    loadingTabContent()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(viewModel.getAccessibilityLabel(for: tab))
                } else {
                    standardTabContent()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(viewModel.getAccessibilityLabel(for: tab))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(theme.chromeBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
        .contentShape(Rectangle())
        .modifier(AspectRatioModifier(shouldLockAspectRatio: viewModel.shouldLockAspectRatio()))
        .onTapGesture {
            viewModel.didTapTab(tab.data)
            viewModel.loggingDelegate?.logArticleTabsArticleClick(wmfProject: tab.data.articles.first?.project)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            Task {
                if tab.info == nil {
                    let populatedTab = await viewModel.populateArticleSummary(tab.data)
                    let info = ArticleTab.Info(subtitle: populatedTab.articles.last?.description, image: populatedTab.articles.last?.imageURL, description: populatedTab.articles.last?.extract)
                    tab.info = info
                }
            }
        }
    }

    private func mainPageTabContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    ZStack {
                        Image("main-page-bg", bundle: .module)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight(horizontalSizeClass: horizontalSizeClass)))
                            .clipped()
                            .overlay(
                                Color.black.opacity(0.6)
                                    .opacity(colorScheme == .dark ? 1 : 0)
                            )

                        Image("globe_yir", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 48)
                            .frame(width: geo.size.width, height: 95, alignment: .center)
                    }
                }
                .frame(height: CGFloat(viewModel.calculateImageHeight(horizontalSizeClass: horizontalSizeClass)))
                .padding(.bottom, 0)

                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action: {
                        viewModel.closeTab(tab: tab)
                    })
                    .accessibilityHidden(true)
                    .padding(.horizontal, 8)
                    .padding(.top, -8)
                    .frame(minWidth: 48, minHeight: 48)
                    .contentShape(Rectangle())
                }
            }
            if let newTabTitle = viewModel.localizedStrings.mainPageTitle {
                tabTitle(title: newTabTitle)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
            } else {
                tabTitle(title: tab.title)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
            }
            VStack(alignment: .leading) {
                Text(viewModel.localizedStrings.mainPageSubtitle)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .lineLimit(1)
                Divider()
                    .frame(width: 24)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                Text(viewModel.localizedStrings.mainPageDescription)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(1.4)
                    .lineLimit(viewModel.shouldLockAspectRatio() ? nil : 3)
            }
            .padding(.horizontal, 10)
        }
    }

    private func loadingTabContent() -> some View {
        Text("")
    }

    private func standardTabContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let imageURL = tab.info?.image {
                        GeometryReader { geo in
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight(horizontalSizeClass: horizontalSizeClass)))
                                    .clipped()
                            } placeholder: {
                                Color(uiColor: theme.paperBackground)
                                    .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight(horizontalSizeClass: horizontalSizeClass)))
                            }
                        }
                        .frame(height: CGFloat(viewModel.calculateImageHeight(horizontalSizeClass: horizontalSizeClass)))
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            tabTitle(title: tab.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 40)
                                .padding([.leading, .top], 10)
                            tabText(tab: tab)
                        }
                    }
                }

                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action: {
                        viewModel.closeTab(tab: tab)
                    })
                    .accessibilityHidden(true)
                    .padding(.horizontal, 8)
                    .padding(.top, -8)
                    .contentShape(Rectangle())
                    .frame(minWidth: 48, minHeight: 48)
                }
            }

            if tab.info?.image != nil {
                VStack(alignment: .leading, spacing: 2) {
                    tabTitle(title: tab.title)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    tabText(tab: tab)
                }
            }

            if tab.info?.image == nil {
                Spacer()
            }
            Spacer()
        }
    }

    private func tabTitle(title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.georgiaCallout)))
            .foregroundStyle(Color(theme.text))
            .lineLimit(1)
            .padding(.bottom, 2)
    }

    private func tabText(tab: ArticleTab) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let subtitle = tab.info?.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .lineLimit(1)
                
                Divider()
                    .frame(width: 24)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            } else {
                Divider()
                    .frame(width: 24)
                    .padding(.bottom, 8)
                    .padding(.top, 6)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }

            if let description = viewModel.description(for: tab) {
                Text(description)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(1.4)
                    .padding(.bottom, 4)
                    .lineLimit(viewModel.shouldLockAspectRatio() ? nil : 3)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}

struct AspectRatioModifier: ViewModifier {
    let shouldLockAspectRatio: Bool

    func body(content: Content) -> some View {
        if shouldLockAspectRatio {
            content.aspectRatio(3/4, contentMode: .fit)
        } else {
            content
        }
    }
}
