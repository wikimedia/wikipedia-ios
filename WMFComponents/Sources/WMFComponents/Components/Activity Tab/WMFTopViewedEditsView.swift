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
            title: viewModel.localizedStrings.contributionsThisMonth,
            dateText: nil,
            additionalAccessibilityLabel: nil,
            onTapModule: viewModel.navigateToContributions,
            content: {
                ForEach(mostViewedViewModel.topViewedArticles) { article in
                    HStack {
                        VStack {
                            Text(article.title)
                        }
                    }
                }
            }, shiftFirstIcon: true
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
