import SwiftUI

public struct WMFSlideShow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding public var currentSlide: Int

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let slides: [SlideShowProtocol]
    
    public init(currentSlide: Binding<Int>, slides: [SlideShowProtocol]) {
        self._currentSlide = currentSlide
        self.slides = slides
    }
    
    public var body: some View {
        Group {
            ForEach(0..<slides.count, id: \.self) { slide in
                WMFYearInReviewScrollView(
                    scrollViewContents: slideView(slide: slide),
                    hasLargeInsets: false,
                    imageName: slides[slide].imageName,
                    imageOverlay: slides[slide].imageOverlay,
                    textOverlay: slides[slide].textOverlay
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(slide)
                    .background(Color(uiColor: theme.midBackground))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func slideView(slide: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(slides[slide].title)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundStyle(Color(uiColor: theme.text))
            Text(slides[slide].subtitle)
                .font(Font(WMFFont.for(.title3)))
                .foregroundStyle(Color(uiColor: theme.text))
            Spacer()
        }
    }
}
    
public protocol SlideShowProtocol {
    var title: String { get }
    var subtitle: String { get }
    var imageName: String { get }
    var imageOverlay: String? { get }
    var textOverlay: String? { get }
}
