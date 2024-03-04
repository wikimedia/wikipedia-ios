import SwiftUI
import Combine

struct WKImageRecommendationsView: View {
    
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    let viewArticleAction: (String) -> Void
    
    var body: some View {
        Group {
            if let articleSummary = viewModel.currentArticleRecommendation?.articleSummary,
               !viewModel.debouncedLoading {
                VStack {
                    WKArticleSummaryView(articleSummary: articleSummary)
                    Spacer()
                        .frame(height: 19)
                    HStack {
                        Spacer()
                        let configuration = WKSmallButton.Configuration(style: .quiet, needsDisclosure: true)
                        WKSmallButton(configuration: configuration, title: "View article") {
                            if let articleTitle = viewModel.currentArticleRecommendation?.title {
                                viewArticleAction(articleTitle)
                            }
                        }
                    }
                    
                    Spacer()
                    Button(action: {
                        viewModel.next {
                            
                        }
                    }, label: {
                        Text("Next")
                    })
                }
                .padding([.leading, .trailing, .bottom])
            } else {
                if !viewModel.debouncedLoading {
                    Text("Empty")
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            viewModel.fetchImageRecommendationsArticleIfNeeded {

            }
        }
    }
}
