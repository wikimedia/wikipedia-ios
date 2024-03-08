import SwiftUI
import Combine

struct WKImageRecommendationsView: View {

    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    let viewArticleAction: (String) -> Void

    var body: some View {
        Group {
            if let articleSummary = viewModel.currentRecommendation?.articleSummary,
               !viewModel.debouncedLoading {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack {
                            HStack {
                                WKArticleSummaryView(articleSummary: articleSummary)
                            }

                            Spacer()
                                .frame(height: 19)
                            HStack {
                                Spacer()
                                let configuration = WKSmallButton.Configuration(style: .quiet, needsDisclosure: true)
                                WKSmallButton(configuration: configuration, title: "View article") {
                                    //TODO: Localizet it
                                    if let articleTitle = viewModel.currentRecommendation?.title {
                                        viewArticleAction(articleTitle)
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing, .bottom])
                        Spacer()
                            .frame(idealHeight: geometry.size.height/3*2)
                    }
                }

            } else {
                if !viewModel.debouncedLoading {
                    Text("Empty")
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            viewModel.fetchImageRecommendationsIfNeeded {

            }
        }
    }
}
