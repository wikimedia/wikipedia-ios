import SwiftUI
import WMFData

public struct WMFArticleTabsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    @ObservedObject var viewModel: WMFArticleTabsViewModel
    
    public init(viewModel: WMFArticleTabsViewModel) {
        self.viewModel = viewModel
    }
    
    private var colorPalette: [UIColor] {
        [theme.destructive, theme.editorGreen]
    }
    
    private var needsMainGridItem: Bool {
        if viewModel.articleTabs.count == 1 {
            if let tab = viewModel.articleTabs.first {
                if let dataTab = tab.dataTab,
                   dataTab.articles.count == 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let columns = viewModel.calculateColumns(for: size)
            let gridItem = GridItem(.flexible())
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: gridItem, count: columns), spacing: 12) {
                    if needsMainGridItem {
                        mainTabCardView(size: size)
                            .aspectRatio(3/4, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    } else {
                        let populatedTabs = viewModel.articleTabs.filter { ($0.dataTab?.articles.count ?? 0) > 0 }
                        ForEach(populatedTabs.sorted(by: { $0.dateCreated < $1.dateCreated })) { tab in
                            tabCardView(tab: tab, size: size)
                                .aspectRatio(3/4, contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    
                }
                .padding()
            }
        }
        .background(Color(theme.midBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("\(viewModel.count) tabs") // todo get localized + pluralized version and update
        .toolbarBackground(Color(uiColor: (theme.paperBackground)), for: .automatic)
    }
    
    private func mainTabCardView(size: CGSize) -> some View {
        VStack(alignment: .leading) {
            Text("Main Page")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(theme.paperBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
        .overlay( /// apply a rounded border
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red, lineWidth: 2)
        )
        .onTapGesture {
            viewModel.didTapMainTab()
        }
    }
    
    private func tabCardView(tab: ArticleTab, size: CGSize) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let imageURL = tab.image {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 95)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } placeholder: {
                            Color(uiColor: theme.paperBackground)
                                .frame(height: 95)
                                .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(theme.paperBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
        .contentShape(Rectangle()) // Ensures full card area is tappable
        .overlay( /// apply a rounded border
            RoundedRectangle(cornerRadius: 12)
                .stroke((tab.dataTab?.isCurrent ?? false) ? .red : .clear, lineWidth: 2)
        )
        .onTapGesture {
            if let dataTab = tab.dataTab {
                viewModel.didTapTab(dataTab)
            }
        }
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
