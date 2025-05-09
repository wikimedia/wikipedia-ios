import SwiftUI
import WMFData

public struct WMFTabsOverviewViewModel {
    let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void
    let didTapMain: () -> Void
    let didTapAddTab: () -> Void
    
    public init(didTapTab: @escaping (WMFArticleTabsDataController.WMFArticleTab) -> Void, didTapMain: @escaping () -> Void, didTapAddTab: @escaping () -> Void) {
        self.didTapTab = didTapTab
        self.didTapMain = didTapMain
        self.didTapAddTab = didTapAddTab
    }
}

public struct WMFTabsOverviewView: View {
    @State private var articleTabs: [WMFArticleTabsDataController.WMFArticleTab] = []
    
    private let dataController: WMFArticleTabsDataController?
    private let viewModel: WMFTabsOverviewViewModel
    
    public init(viewModel: WMFTabsOverviewViewModel) {
        self.viewModel = viewModel
        self.dataController = try? WMFArticleTabsDataController()
    }
    
    public var body: some View {
        List {
            if articleTabs.count == 1 && articleTabs[0].articles.count == 0 {
                Text("Main Page")
                    .onTapGesture {
                        viewModel.didTapMain()
                    }
            } else {
                let populatedArticleTabs = articleTabs.filter { $0.articles.count > 0 }
                ForEach(populatedArticleTabs, id: \.identifier) { tab in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tab.articles.last?.title ?? "")
                                    .font(.headline)
                                if let description = tab.articles.last?.description {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let imageURL = tab.articles.last?.imageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        if let summary = tab.articles.last?.summary {
                            Text(summary)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .onTapGesture {
                        viewModel.didTapTab(tab)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        guard let dataController else { return }
                        for index in indexSet {
                            let tab = articleTabs[index]
                            do {
                                try await dataController.deleteArticleTab(identifier: tab.identifier)
                                await MainActor.run {
                                    articleTabs.remove(at: index)
                                }
                            } catch {
                                print("Error deleting article tab: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                guard let dataController else { return }
                do {
                    let tabs = try await dataController.fetchAllArticleTabs()
                    let sortedTabs = tabs.sorted { $0.timestamp < $1.timestamp }
                    await MainActor.run {
                        articleTabs = sortedTabs
                    }
                } catch {
                    print("Error fetching article tabs: \(error)")
                }
            }
        }
    }
}
