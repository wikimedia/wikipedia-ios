import SwiftUI
import WMFData

public struct WMFSlideShow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Binding public var currentSlide: Int
    public var infoAction: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    let slides: [SlideShowProtocol]
    
    public init(
        currentSlide: Binding<Int>,
        slides: [SlideShowProtocol],
        infoAction: @escaping () -> Void
    ) {
        self._currentSlide = currentSlide
        self.slides = slides
        self.infoAction = infoAction
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
    
    private func subtitleAttributedString(slide: Int) -> AttributedString {
        let text = slides[slide].subtitle
        return (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
    
    private func slideView(slide: Int) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Text(slides[slide].title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                    Button {
                        infoAction()
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .foregroundStyle(Color(uiColor: theme.icon))
                            .frame(width: 24, height: 24, alignment: .trailing)
                    }
                }
            }
            Text(subtitleAttributedString(slide: slide))
                .font(Font(WMFFont.for(.title3)))
                .foregroundStyle(Color(uiColor: theme.text))
                .accentColor(Color(uiColor: theme.link))
                .frame(maxWidth: .infinity, alignment: .leading)
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
    var infoURL: URL? { get }
}
