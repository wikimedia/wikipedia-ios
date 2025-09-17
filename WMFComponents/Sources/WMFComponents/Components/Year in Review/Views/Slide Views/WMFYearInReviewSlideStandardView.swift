import SwiftUI

struct WMFYearInReviewSlideStandardView: View {
    let viewModel: WMFYearInReviewSlideStandardViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideStandardViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

fileprivate struct WMFYearInReviewSlideStandardViewContent: View {
    let viewModel: WMFYearInReviewSlideStandardViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private func subtitleAttributedString(subtitle: String) -> AttributedString {
        if let attributedString = try? AttributedString(
            markdown: subtitle,
            options: .init(interpretedSyntax: .full)
        ) {
            return attributedString
        }
        
        return AttributedString(subtitle)
    }
    
    private var subtitleStyles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.body), boldFont: WMFFont.for(.boldBody), italicsFont: WMFFont.for(.body), boldItalicsFont: WMFFont.for(.body), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                ZStack {
                    Image(viewModel.gifName, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    WMFGIFImageView(viewModel.gifName)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(viewModel.altText)
            }
            
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Spacer()
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                        Button {
                            viewModel.tappedInfo()
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
                
                switch viewModel.subtitleType {
                case .html:
                    WMFHtmlText(html: viewModel.subtitle, styles: subtitleStyles)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                case .markdown:
                    Text(subtitleAttributedString(subtitle: viewModel.subtitle))
                        .font(Font(WMFFont.for(.body)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .accentColor(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .standard:
                    Text(viewModel.subtitle)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .accentColor(Color(uiColor: theme.link))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}
