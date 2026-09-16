import SwiftUI

struct OLDWMFYearInReviewBodyView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: OLDWMFYearInReviewViewModel
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    init(viewModel: OLDWMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if viewModel.isShowingIntro {
            if let introV3ViewModel = viewModel.introV3ViewModel {
                OLDWMFYearInReviewSlideIntroV3View(viewModel: introV3ViewModel, isPopulatingReport:$viewModel.isPopulatingReport)
            }
        } else {
            VStack {
                
                TabView(selection: $viewModel.currentSlideIndex) {

                    ForEach(Array(viewModel.slides.enumerated()), id: \.offset) { index, slide in
                        if case .standard(let standardViewModel) = slide {
                            OLDWMFYearInReviewSlideStandardView(viewModel: standardViewModel)
                        }

                        if case .mostReadDateV3(let mostReadDateSlideV3ViewModel) = slide {
                            OLDWMFYearInReviewSlideMostReadDateV3View(viewModel: mostReadDateSlideV3ViewModel)
                        }

                        if case .location(let locationViewModel) = slide {
                            OLDWMFYearInReviewSlideLocationView(viewModel: locationViewModel)
                        }

                        if case .highlights(let highlightsViewModel) = slide {
                            OLDWMFYearInReviewSlideHighlightsView(viewModel: highlightsViewModel)
                        }
                        if case .contribution(let contributionsViewModel) = slide {
                            OLDWMFYearInReviewContributionSlideView(viewModel: contributionsViewModel, parentViewModel: viewModel)
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
