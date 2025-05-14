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
                LazyVGrid(columns: Array(repeating: gridItem, count: columns), spacing: 12) {

                    ForEach(viewModel.articleTabs.sorted(by: { $0.dateCreated < $1.dateCreated })) { tab in
                        if tab.isMain {
                            tabCardView(content: mainPageTabContent(tab: tab), tabData: tab.data)
								.accessibilityElement(children: .combine)
                            	.accessibilityLabel(Text(viewModel.getAccessibilityLabel(for: tab)))
                        } else {
                            tabCardView(content: standardTabContent(tab: tab), tabData: tab.data)
								.accessibilityElement(children: .combine)
                            	.accessibilityLabel(Text(viewModel.getAccessibilityLabel(for: tab)))
                        }
                    }
                    
                }
                .padding()
            }
        }
        .background(Color(theme.midBackground))
        .toolbarBackground(Color(uiColor: (theme.paperBackground)), for: .automatic)
    }
    
    private func mainPageTabContent(tab: ArticleTab) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    ZStack {
                        Image("main-page-bg", bundle: .module)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: 95)
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

                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action: {
                        viewModel.closeTab(tab: tab)
                    })
                    .padding([.horizontal, .top], 12)
                    .contentShape(Rectangle())
                }
            }

            tabTitle(title: tab.title)
                .padding(.horizontal, 10)
                .padding(.top, 8)

            VStack(alignment: .leading) {
                Text(viewModel.localizedStrings.mainPageSubtitle)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.secondaryText))
                    .lineLimit(1)

                Divider()
                    .frame(width: 24)
                    .padding(.vertical, 6)

                Text(viewModel.localizedStrings.mainPageDescription)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(5)
            }
            .padding([.horizontal, .bottom], 10)
        }
    }
    
    private func standardTabContent(tab: ArticleTab) -> some View {
        VStack(alignment: .leading) {
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
                                    .frame(width: geo.size.width, height: GFloat(viewModel.calculateImageHeight()))
                            }
                        }
                    } else {
                        tabTitle(title: tab.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 40)
                            .padding(.top, 12)
                            .padding(.leading, 10)
                    }
                }

                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action:{
                        viewModel.closeTab(tab: tab)
                    })
                    .padding([.horizontal, .top], 12)
                    .contentShape(Rectangle())
                }
            }

            if tab.image != nil {
                tabTitle(title: tab.title)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
            }

            tabText(tab: tab)

            if tab.image == nil {
                Spacer()
                Spacer()
            }
        }
    }
    
    private func tabCardView(content: some View, tabData: WMFArticleTabsDataController.WMFArticleTab) -> some View {
        content
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(theme.paperBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
        .contentShape(Rectangle()) // Ensures full card area is tappable
        .onTapGesture {
            viewModel.didTapTab(tabData)
        }
        .aspectRatio(3/4, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func tabTitle(title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.georgiaTitle3)))
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
                .padding(.vertical, 6)
            if let description = tab.description {
                Text(description)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
                    .lineSpacing(5)
            } else {
                Spacer()
                Spacer()
            }
        }
        .padding([.horizontal, .bottom], 10)
    }
}
