import SwiftUI
import Combine
import WMFData

struct WMFImageRecommendationsView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFImageRecommendationsViewModel
    @ObservedObject var tooltipGeometryValues: WMFTooltipGeometryValues
    
    let errorTryAgainAction: () -> Void
    let viewArticleAction: (String) -> Void
    let emptyViewAppearanceAction: () -> Void

    var body: some View {
        Group {
            ZStack {
                Color(appEnvironment.theme.paperBackground)
                if let articleSummary = viewModel.currentRecommendation?.articleSummary,
                   !viewModel.debouncedLoading {
                    
                    WMFImageRecommendationsArticleSummaryView(viewModel: viewModel, articleSummary: articleSummary, viewArticleAction: viewArticleAction)

                } else {
                    if !viewModel.debouncedLoading {
                        if viewModel.loadingError != nil {
                            WMFErrorView(viewModel: WMFErrorViewModel(localizedStrings: viewModel.localizedStrings.errorLocalizedStrings, image: WMFIcon.error), tryAgainAction: errorTryAgainAction)
                        } else {
                            WMFEmptyView(viewModel: WMFEmptyViewModel(localizedStrings: viewModel.localizedStrings.emptyLocalizedStrings, image: WMFIcon.checkPhoto, imageColor: appEnvironment.theme.link, numberOfFilters: nil), type: .noItems)
                                .onAppear {
                                    emptyViewAppearanceAction()
                                }
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            .ignoresSafeArea()
        }
        .environmentObject(tooltipGeometryValues)
    }
}

fileprivate struct WMFImageRecommendationsArticleSummaryView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: WMFImageRecommendationsViewModel
    
    let articleSummary: WMFArticleSummary
    let viewArticleAction: (String) -> Void
    
    var isRTL: Bool {
        return viewModel.semanticContentAttribute == .forceRightToLeft
    }
    
    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 16
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    HStack {
                        WMFArticleSummaryView(articleSummary: articleSummary)
                            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                    }
                    Spacer()
                        .frame(height: 19)
                    HStack {
                        Spacer()
                        let configuration = WMFSmallButton.Configuration(style: .quiet, trailingIcon: WMFSFSymbolIcon.for(symbol: .chevronForward, font: .mediumSubheadline))
                        WMFSmallButton(configuration: configuration, title: viewModel.localizedStrings.viewArticle) {
                            if let articleTitle = viewModel.currentRecommendation?.title {
                                viewArticleAction(articleTitle)
                            }
                        }
                    }
                }
                .padding([.leading, .trailing, .bottom], sizeClassPadding)
                Spacer()
                    .frame(idealHeight: geometry.size.height/3*2)
            }
        }
    }
}
