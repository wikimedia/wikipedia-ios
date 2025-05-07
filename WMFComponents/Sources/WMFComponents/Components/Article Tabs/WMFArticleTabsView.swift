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
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                let size = geometry.size
                let columns = viewModel.calculateColumns(for: size)
                let gridItem = GridItem(.flexible())
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: gridItem, count: columns), spacing: 12) {
                        ForEach(viewModel.articleTabs.sorted(by: { $0.dateCreated < $1.dateCreated })) { tab in
                            tabCardView(tab: tab, size: size)
                                .aspectRatio(3/4, contentMode: .fit)
                                .clipped()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(theme.baseBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("\(viewModel.count) tabs") // todo get localized + pluralized version and update
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.addTab()
                }) {
                    if let image = WMFIcon.plus {
                        Image(uiImage: image)
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                }
            }
        }
    }
    
    private func tabCardView(tab: ArticleTab, size: CGSize) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                if let imageURL = tab.image {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: CGFloat(viewModel.calculateImageHeight(for: size)))
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } placeholder: {
                        Color(uiColor: theme.paperBackground)
                            .frame(height: 1)
                    }
                } else {
                    tabTitle(title: tab.title)
                        .padding(.trailing, 40)
                        .padding([.leading, .top], 12)
                }
                
                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action:{ viewModel.closeTab(tab: tab) })
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .padding([.horizontal, .top], 12)
                }
            }
            if tab.image != nil {
                tabTitle(title: tab.title)
                    .padding([.horizontal], 12)
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
    }
    
    private func tabTitle(title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.georgiaTitle3)))
            .foregroundStyle(Color(theme.text))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    
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
            if let description = tab.description {
                Text(description)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(theme.text))
            } else {
                Spacer()
                Spacer()
            }
        }
       // .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding([.horizontal, .bottom], 10)
    }
}
