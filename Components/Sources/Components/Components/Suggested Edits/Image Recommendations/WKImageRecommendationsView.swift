import SwiftUI
import Combine
import WKData

struct WKImageRecommendationsView: View {

    @ObservedObject var appEnvironment = WKAppEnvironment.current
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    let viewArticleAction: (String) -> Void

    var body: some View {
        Group {
            ZStack {
                Color(appEnvironment.theme.paperBackground)
                if let articleSummary = viewModel.currentRecommendation?.articleSummary,
                   !viewModel.debouncedLoading {
                    
                    WKImageRecommendationsArticleSummaryView(viewModel: viewModel, articleSummary: articleSummary, viewArticleAction: viewArticleAction)

                } else {
                    if !viewModel.debouncedLoading {
                        WKEmptyView(viewModel: WKEmptyViewModel(localizedStrings: viewModel.localizedStrings.emptyLocalizedStrings, image: WKIcon.checkPhoto, imageColor: appEnvironment.theme.link, numberOfFilters: nil), type: .noItems)
                    } else {
                        ProgressView()
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            viewModel.fetchImageRecommendationsIfNeeded {

            }
        }
    }
}

fileprivate struct WKImageRecommendationsArticleSummaryView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    let articleSummary: WKArticleSummary
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
                        WKArticleSummaryView(articleSummary: articleSummary)
                            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                    }
                    Spacer()
                        .frame(height: 19)
                    HStack {
                        Spacer()
                        let configuration = WKSmallButton.Configuration(style: .quiet, needsDisclosure: true)
                        WKSmallButton(configuration: configuration, title: viewModel.localizedStrings.viewArticle) {
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
