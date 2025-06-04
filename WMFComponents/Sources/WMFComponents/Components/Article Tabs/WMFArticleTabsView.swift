import SwiftUI
import WMFData

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
        Group {
            if isReady {
                tabsGrid
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(theme.midBackground))
            }
        }
        .onReceive(viewModel.$articleTabs) { tabs in
            guard !tabs.isEmpty, !isReady else { return }
            Task {
                if let tab = await viewModel.getCurrentTab() {
                    currentTabID = tab.id
                    isReady = true
                }
            }
        }
        .background(Color(theme.midBackground))
        .toolbarBackground(Color(theme.midBackground), for: .automatic)
    }

    private var tabsGrid: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                let columns = viewModel.calculateColumns(for: geometry.size)
                let gridItem = GridItem(.flexible())

                ScrollView {
                    LazyVGrid(columns: Array(repeating: gridItem, count: columns)) {
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
}

fileprivate struct WMFArticleTabsViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) var colorScheme

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
        .onTapGesture {
            viewModel.didTapTab(tab.data)
            viewModel.loggingDelegate?.logArticleTabsArticleClick(wmfProject: tab.data.articles.first?.project)
        }
        .aspectRatio(3/4, contentMode: .fit)
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
                            .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight()))
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
                .frame(height: CGFloat(viewModel.calculateImageHeight()))
                .padding(.bottom, 0)

                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action: {
                        viewModel.closeTab(tab: tab)
                    })
                    .accessibilityHidden(true)
                    .padding(.horizontal, 8)
                    .padding(.top, -8)
                    .contentShape(Rectangle())
                    .frame(minWidth: 44, minHeight: 44)
                }
            }

            tabTitle(title: tab.title)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 2)

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
                                    .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight()))
                                    .clipped()
                            } placeholder: {
                                Color(uiColor: theme.paperBackground)
                                    .frame(width: geo.size.width, height: CGFloat(viewModel.calculateImageHeight()))
                            }
                        }
                        .frame(height: CGFloat(viewModel.calculateImageHeight()))
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
                    .frame(minWidth: 44, minHeight: 44)
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
            Group {
                if let subtitle = tab.info?.subtitle {
                    Text(subtitle)
                } else {
                    Text(" ")
                        .hidden()
                }
            }
            .font(Font(WMFFont.for(.caption1)))
            .foregroundStyle(Color(theme.secondaryText))
            .lineLimit(1)

            Divider()
                .frame(width: 24)
                .padding(.vertical, 8)
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            if let description = viewModel.description(for: tab) {
                Text(description)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(1.4)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
}
