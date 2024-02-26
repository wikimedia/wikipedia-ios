import SwiftUI

struct WKImageRecommendationsView: View {
    
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    @State private var loading: Bool = false
    let viewArticleAction: (String) -> Void
    
    var body: some View {
        Group {
            if let articleSummary = viewModel.currentRecommendation?.articleSummary,
               !loading {
                VStack {
                    WKArticleSummaryView(articleSummary: articleSummary)
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
                        loading = true
                        viewModel.next {
                            loading = false
                        }
                    }, label: {
                        Text("Next")
                    })
                }
                .padding([.leading, .trailing, .bottom])
            } else {
                if !loading {
                    Text("Empty")
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            loading = true
            viewModel.fetchImageRecommendationsIfNeeded {
                loading = false
            }
        }
    }
}
