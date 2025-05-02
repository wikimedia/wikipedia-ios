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
                    LazyVGrid(columns: Array(repeating: gridItem, count: columns), spacing: 0) {
                        ForEach(viewModel.articleTabs) { tab in
                            tabCardView(tab: tab)
                                .aspectRatio(3/4, contentMode: .fill)
                                .padding()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .background(Color(theme.baseBackground))
    }
    
    private func tabCardView(tab: ArticleTab) -> some View {
        VStack(alignment: .leading) {
            ZStack {
                Color.white
                AsyncImage(url: tab.image) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.white
                }
            }
            .frame(height: 95)
            .frame(maxWidth: .infinity)
            .clipped()
            VStack(alignment: .leading) {
                Text(tab.title)
                    .font(Font(WMFFont.for(.georgiaTitle3)))
                    .foregroundStyle(Color(theme.text))
                if let subtitle = tab.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.secondaryText))
                } else {
                    Spacer()
                }
                Divider()
                    .frame(width: 24)
                if let description = tab.description {
                    Text(description)
                        .font(Font(WMFFont.for(.caption1)))
                        .foregroundStyle(Color(theme.text))
                        .lineLimit(UIDevice.current.userInterfaceIdiom == .pad ? 3 : 4)
                } else {
                    Spacer()
                }
            }
            .padding(10)
        }
        .background(Color(theme.paperBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 0)
    }
}
