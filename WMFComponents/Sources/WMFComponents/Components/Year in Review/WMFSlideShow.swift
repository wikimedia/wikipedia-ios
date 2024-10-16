import SwiftUI

public struct WMFSlideShow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding private var currentSlide: Int
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let slides: [SlideShowProtocol]
    
    public init(currentSlide: Binding<Int>, slides: [SlideShowProtocol]) {
        self._currentSlide = currentSlide
        self.slides = slides
        
        UIPageControl.appearance().currentPageIndicatorTintColor = theme.link
        UIPageControl.appearance().pageIndicatorTintColor = theme.link.withAlphaComponent(0.3)
    }
    
    public var body: some View {
        VStack {
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { slide in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(slides[slide].imageName, bundle: .module)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(slides[slide].title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundStyle(Color(uiColor: theme.text))
                            Text(slides[slide].subtitle)
                                .font(Font(WMFFont.for(.title3)))
                                .foregroundStyle(Color(uiColor: theme.text))
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(slide)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding([.leading, .trailing], 36)
            .padding(.top, 48)
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 34)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
    
public protocol SlideShowProtocol {
    var title: String { get }
    var subtitle: String { get }
    var imageName: String { get }
}
