import SwiftUI
import WMFData

public struct WMFArticleTabsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) var colorScheme
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    @ObservedObject var viewModel: WMFArticleTabsViewModel
    
    public init(viewModel: WMFArticleTabsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let columns = viewModel.calculateColumns(for: size)
            let gridItem = GridItem(.flexible())
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: gridItem, count: columns)) {
                    ForEach(viewModel.articleTabs.sorted(by: { $0.dateCreated < $1.dateCreated })) { tab in
                        if tab.isLoading {
                            tabCardView(content: loadingTabContent(tab: tab), tabData: tab.data, tab: tab)
                                .padding(4)
                        } else {
                            if tab.isMain {
                                tabCardView(content: mainPageTabContent(tab: tab), tabData: tab.data, tab: tab)
                                    .padding(4)
                                
                            } else {
                                tabCardView(content: standardTabContent(tab: tab), tabData: tab.data, tab: tab)
                                    .padding(4)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .background(Color(theme.midBackground))
        .toolbarBackground(Color(uiColor: (theme.paperBackground)), for: .automatic)
    }
    
    private func mainPageTabContent(tab: ArticleTab) -> some View {
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

            VStack(alignment: .leading) {
                Text(viewModel.localizedStrings.mainPageSubtitle)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .lineLimit(1)
                Divider()
                    .frame(width: 24)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .foregroundStyle(Color(uiColor: theme.border))
                Text(viewModel.localizedStrings.mainPageDescription)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(5)
                    .padding(.bottom, 5)
            }
            .padding([.horizontal], 10)
        }
    }
    
    private func loadingTabContent(tab: ArticleTab) -> some View {
        Text("Loading")
    }

    
    private func standardTabContent(tab: ArticleTab) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let imageURL = tab.image {
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
                        tabTitle(title: tab.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 40)
                            .padding([.leading, .top], 10)
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

            if tab.image != nil {
                tabTitle(title: tab.title)
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
            }

            tabText(tab: tab)

            if tab.image == nil {
                Spacer()
            }
            Spacer()
        }
    }
    
    private func tabCardView(content: some View, tabData: WMFArticleTabsDataController.WMFArticleTab, tab: ArticleTab) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(theme.paperBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.didTapTab(tabData)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.getAccessibilityLabel(for: tab))
            .accessibilityActions {
                accessibilityAction(named: viewModel.localizedStrings.openTabAccessibility) {
                    viewModel.didTapTab(tabData)
                }

                if viewModel.shouldShowCloseButton {
                    accessibilityAction(named: viewModel.localizedStrings.closeTabAccessibility) {
                        viewModel.closeTab(tab: tab)
                    }
                }
            }
            .onAppear {
                Task {
                    let populatedTab = await viewModel.populateSummary(tabData)
                    tab.image = populatedTab.articles.last?.imageURL
                    tab.subtitle = populatedTab.articles.last?.description
                    tab.description = populatedTab.articles.last?.summary
                    tab.isLoading = false
                }
                
            }
    }

    private func tabTitle(title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.georgiaCallout)))
            .foregroundStyle(Color(theme.text))
            .lineLimit(1)
    }
    
    private func tabText(tab: ArticleTab) -> some View {
        VStack(alignment: .leading) {
            if let subtitle = tab.subtitle {
                Text(subtitle)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .lineLimit(1)
            }
            Divider()
                .frame(width: 24)
                .padding(.top, 4)
                .padding(.bottom, 6)
                .foregroundStyle(Color(uiColor: theme.border))
            if let description = tab.description {
                Text(description)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(5)
                    .padding(.bottom, 5)
            } else {
                Spacer()
            }
        }
        .padding([.horizontal], 10)
    }
}
