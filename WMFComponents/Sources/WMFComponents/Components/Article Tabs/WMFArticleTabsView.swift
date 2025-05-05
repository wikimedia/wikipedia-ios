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
    }
    
    private func tabCardView(tab: ArticleTab, size: CGSize) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
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
                            .frame(minHeight: 95)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Color(uiColor: theme.paperBackground)
                        .frame(minHeight: CGFloat(viewModel.calculateImageHeight(for: size)))
                        .frame(maxWidth: .infinity)
                }
                
                
                if viewModel.shouldShowCloseButton {
                    Button(action: {
                        print("close")
                    }) {
                        if let image = WMFSFSymbolIcon.for(symbol: .closeCircleFill, paletteColors: [theme.destructive, theme.editorGreen]) {
                            Image(uiImage: image)
                                .scaledToFit()
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }
            }
            
            VStack(alignment: .leading) {
                Text(tab.title)
                    .font(Font(WMFFont.for(.georgiaTitle3)))
                    .foregroundStyle(Color(theme.text))
                    .lineLimit(1)
                if let subtitle = tab.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))
                        .lineLimit(1)
                } else {
                    Spacer()
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(theme.paperBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
    }
}
