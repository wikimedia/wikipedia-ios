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
        if viewModel.isShowingIntro,
           let introViewModel = viewModel.introViewModel {
            WMFYearInReviewSlideIntroView(viewModel: introViewModel)
        } else {
            VStack {
                
                TabView(selection: $viewModel.currentSlideIndex) {
                    
                    ForEach(Array(viewModel.slides.enumerated()), id: \.offset) { index, slide in
                        if case .standard(let standardViewModel) = slide {
                            WMFYearInReviewSlideStandardView(viewModel: standardViewModel)
                        }
                        
                        if case .location(let locationViewModel) = slide {
                            WMFYearInReviewSlideLocationView(viewModel: locationViewModel)
                        }
                        
                        if case .contribution(let contributionsViewModel) = slide {
                            WMFYearInReviewContributionSlideView(viewModel: contributionsViewModel)
                        }
                    }
                    
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
