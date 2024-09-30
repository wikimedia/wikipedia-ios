import SwiftUI

public struct WMFSlideShow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @State private var currentSlide = 0
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let slides: [YearInReviewSlide]
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect() // TODO:remove
    
    public init(currentSlide: Int = 0, slides: [YearInReviewSlide]) {
        self.currentSlide = currentSlide
        self.slides = slides
        
        UIPageControl.appearance().currentPageIndicatorTintColor = theme.link.withAlphaComponent(0.3)
        UIPageControl.appearance().pageIndicatorTintColor = theme.link.withAlphaComponent(0.3)
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { slide in
                    Text(slides[slide].title)
                        .tag(slide)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(maxWidth: .infinity)
            .cornerRadius(10)
            .padding([.leading, .trailing], 10)
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 34)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(timer) { _ in
            withAnimation {
                currentSlide = (currentSlide + 1) % slides.count
            }
        }
    }

}
