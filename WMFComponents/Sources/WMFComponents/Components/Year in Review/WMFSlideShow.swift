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
        return HtmlUtils.Styles(font: WMFFont.for(.title3), boldFont: WMFFont.for(.boldTitle3), italicsFont: WMFFont.for(.title3), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    @State var locationName: String? = nil
    @State var randomArticles: [String] = []
    
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
            ForEach(0..<slides.count, id: \.self) { slideIndex in
                let slide = slides[slideIndex]
                WMFYearInReviewScrollView(
                    scrollViewContents: slideView(slideIndex: slideIndex),
                    hasLargeInsets: false,
                    gifName: slides[slideIndex].gifName,
                    altText: slides[slideIndex].altText,
                    locationArticles: slide.locationArticles, locationName: $locationName, randomArticles: $randomArticles
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(slideIndex)
                .background(Color(uiColor: theme.midBackground))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func subtitleAttributedString(slideIndex: Int) -> AttributedString {
        let text = slides[slideIndex].subtitle
        return (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }
    
    private func title(slideIndex: Int) -> String {
        if let locationName, slides[slideIndex].isLocationSlide == true {
            return "You read the most articles in the \(locationName) area."
        } else {
            return slides[slideIndex].title
        }
    }
    
    private func randomArticlesText(slideIndex: Int) -> String? {
        guard randomArticles.count > 0, slides[slideIndex].isLocationSlide == true else { return nil }
        
        if randomArticles.count == 1 {
            return "This includes the article <b>\(randomArticles[0])</b>."
        }
        
        if randomArticles.count == 2 {
            return "This includes the articles <b>\(randomArticles[0])</b> and <b>\(randomArticles[1])</b>."
        }
        
        if randomArticles.count > 2 {
            return "This includes the articles <b>\(randomArticles[0])</b>, <b>\(randomArticles[1])</b> and <b>\(randomArticles[2])</b>."
        }
        
        return nil
    }
    
    private func slideView(slideIndex: Int) -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Text(title(slideIndex: slideIndex))
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
            if let randomArticlesText = randomArticlesText(slideIndex: slideIndex) {
                WMFHtmlText(html: randomArticlesText, styles: subtitleStyles)
            } else if slides[slideIndex].isSubtitleAttributedString ?? false {
                WMFHtmlText(html: slides[slideIndex].subtitle, styles: subtitleStyles)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                Text(subtitleAttributedString(slideIndex: slideIndex))
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
    var locationArticles: [WMFLegacyPageView] { get }
    var isLocationSlide: Bool { get }
}
