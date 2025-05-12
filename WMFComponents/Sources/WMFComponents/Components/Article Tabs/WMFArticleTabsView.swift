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
        GeometryReader { geometry in
            let size = geometry.size
            let columns = viewModel.calculateColumns(for: size)
            let gridItem = GridItem(.flexible())
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: gridItem, count: columns), spacing: 12) {
                    ForEach(viewModel.articleTabs.sorted(by: { $0.dateCreated < $1.dateCreated })) { tab in
                        tabCardView(tab: tab)
                            .aspectRatio(3/4, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(Text(viewModel.getAccessibilityLabel(for: tab)))
                    }
                }
                .padding()
            }
        }
        .background(Color(theme.midBackground))
        .toolbarBackground(Color(uiColor: (theme.paperBackground)), for: .automatic)
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
    
    private func tabCardView(tab: ArticleTab) -> some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
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
                } else {
                    tabTitle(title: tab.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 40)
                        .padding(.top, 12)
                        .padding(.leading, 10)
                }
                
                if viewModel.shouldShowCloseButton {
                    WMFCloseButton(action:{ viewModel.closeTab(tab: tab) })
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .padding([.horizontal, .top], 12)
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
