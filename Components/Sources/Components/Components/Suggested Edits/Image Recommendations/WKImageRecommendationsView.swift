import SwiftUI
import Combine

struct WKImageRecommendationsView: View {
    
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    let viewArticleAction: (String) -> Void
    
    var isRTL: Bool {
        return viewModel.semanticContentAttribute == .forceRightToLeft
    }
    
    var body: some View {
        Group {
            if let articleSummary = viewModel.currentRecommendation?.articleSummary,
               !viewModel.debouncedLoading {
                VStack {
                    WKArticleSummaryView(articleSummary: articleSummary)
                        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                    Spacer()
                        .frame(height: 19)
                    HStack {
                        Spacer()
                        let configuration = WKSmallButton.Configuration(style: .quiet, needsDisclosure: true)
                        WKSmallButton(configuration: configuration, title: "View article") {
                            if let articleTitle = viewModel.currentRecommendation?.title {
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
            viewModel.fetchImageRecommendationsIfNeeded {

            }
        }
    }
}
