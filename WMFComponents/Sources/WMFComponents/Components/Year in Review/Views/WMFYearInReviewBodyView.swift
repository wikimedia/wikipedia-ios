import SwiftUI

struct WMFYearInReviewBodyView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if viewModel.isShowingIntro {
            if let introV3ViewModel = viewModel.introV3ViewModel {
                WMFYearInReviewSlideIntroV3View(viewModel: introV3ViewModel, isPopulatingReport:$viewModel.isPopulatingReport)
            }
        } else {
            VStack {
                
                TabView(selection: $viewModel.currentSlideIndex) {

                    ForEach(Array(viewModel.slides.enumerated()), id: \.offset) { index, slide in
                        if case .standard(let standardViewModel) = slide {
                            WMFYearInReviewSlideStandardView(viewModel: standardViewModel)
                        }

                        if case .mostReadDateV3(let mostReadDateSlideV3ViewModel) = slide {
                            WMFYearInReviewSlideMostReadDateV3View(viewModel: mostReadDateSlideV3ViewModel)
                        }

                        if case .location(let locationViewModel) = slide {
                            WMFYearInReviewSlideLocationView(viewModel: locationViewModel)
                        }

                        if case .highlights(let highlightsViewModel) = slide {
                            WMFYearInReviewSlideHighlightsView(viewModel: highlightsViewModel)
                        }
                        if case .contribution(let contributionsViewModel) = slide {
                            WMFYearInReviewContributionSlideView(viewModel: contributionsViewModel, parentViewModel: viewModel)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
