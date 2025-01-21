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
    
    private var subtitleStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.title3), boldFont: WMFFont.for(.title3), italicsFont: WMFFont.for(.title3), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
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
                    gifName: slides[slide].gifName,
                    altText: slides[slide].altText
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
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Spacer()
                if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                    Button {
                        infoAction()
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .foregroundStyle(Color(uiColor: theme.icon))
                            .frame(width: 24, height: 24)
                            .alignmentGuide(.top) { dimensions in
                                dimensions[.top] - 5
                            }
                    }
                }
            }
            if slides[slide].isSubtitleAttributedString ?? false {
                WMFHtmlText(html: slides[slide].subtitle, styles: subtitleStyles)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text(subtitleAttributedString(slide: slide))
                    .font(Font(WMFFont.for(.title3)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .accentColor(Color(uiColor: theme.link))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }
}
    
public protocol SlideShowProtocol {
    var title: String { get }
    var subtitle: String { get }
    var gifName: String { get }
    var altText: String { get }
    var isSubtitleAttributedString: Bool? { get }
    var infoURL: URL? { get }
}
