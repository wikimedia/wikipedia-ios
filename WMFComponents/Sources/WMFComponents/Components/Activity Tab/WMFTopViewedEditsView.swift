import SwiftUI
import WMFData
import Charts
import Foundation

public struct TopViewedEditsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let viewModel: WMFActivityTabViewModel
    let mostViewedViewModel: MostViewedArticlesViewModel
    
    public init(viewModel: WMFActivityTabViewModel, mostViewedViewModel: MostViewedArticlesViewModel) {
        self.viewModel = viewModel
        self.mostViewedViewModel = mostViewedViewModel
    }
    
    public var body: some View {
        WMFActivityTabInfoCardView(
            icon: WMFSFSymbolIcon.for(symbol: .lineDiagonalArrow),
            title: viewModel.localizedStrings.mostViewed,
            dateText: nil,
            onTapModule: nil,
            content: {
                ForEach(mostViewedViewModel.topViewedArticles) { article in
                    let cleanTitle = article.title.replacingOccurrences(of: "_", with: " ")

                    WMFAsyncPageRow(
                        viewModel: WMFAsyncPageRowViewModel(
                            id: article.id,
                            title: cleanTitle,
                            projectID: mostViewedViewModel.projectID,
                            iconAccessibilityLabel: "",
                            tapAction: {
                                let url = mostViewedViewModel.getArticleURL(for: article)
                                guard let url else { return }
                                viewModel.onTapArticle?(url)
                            }, footerText: viewModel.localizedStrings.viewsString(article.viewsCount)
                        )
                    )
                }
            }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
