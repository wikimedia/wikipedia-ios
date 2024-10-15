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
    }
    
    public var body: some View {
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
            .background(Color(uiColor: theme.midBackground))
        }
    }
}
    
public protocol SlideShowProtocol {
    var title: String { get }
    var subtitle: String { get }
    var imageName: String { get }
}
