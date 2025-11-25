import SwiftUI

public struct WMFYearInReviewSlideHighlightsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFYearInReviewSlideHighlightsViewModel
    
    var titleAttributedString: AttributedString {
        let html = "<b>" + viewModel.localizedStrings.title + "</b>" + " " + viewModel.localizedStrings.subtitle
        let fallback = viewModel.localizedStrings.title + " " + viewModel.localizedStrings.subtitle
        
        var maxTraitCollection: UITraitCollection
        
        // Only allow growing for iPad
        let hSizeClass = UITraitCollection.current.horizontalSizeClass
        let vSizeClass = UITraitCollection.current.verticalSizeClass
        
        if hSizeClass == .compact {
            maxTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        } else if vSizeClass == .compact {
            maxTraitCollection = UITraitCollection(preferredContentSizeCategory: .large)
        } else {
            maxTraitCollection = WMFAppEnvironment.current.traitCollection
        }
        
        let regularFont = WMFFont.for(.headline, compatibleWith: maxTraitCollection)
        let boldFont = WMFFont.for(.boldHeadline, compatibleWith: maxTraitCollection)
        
        let styles = HtmlUtils.Styles(font: regularFont, boldFont: boldFont, italicsFont: regularFont, boldItalicsFont: regularFont, color: .white, linkColor: theme.link, lineSpacing: 1)
        
        return(try? HtmlUtils.attributedStringFromHtml(html, styles: styles)) ?? AttributedString(fallback)
    }
    
    var scrollViewContents: some View {
        WMFYearInReviewInfoboxView(
            viewModel: viewModel.infoBoxViewModel,
            isSharing: false
        )
    }
    
    func dynamicMaxInfoboxHeight(availableHeight: CGFloat) -> CGFloat {
        if availableHeight < 530 {
            
            // SE size
            let preferredContentSize = UITraitCollection.current.preferredContentSizeCategory
            
            if preferredContentSize.isAccessibilityCategory {
                return 200
            }
            
            return 300
        }
        return 414
    }
    
    @State var availableHeight: CGFloat?

    public var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                GradientBackgroundView()
                
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            Text(titleAttributedString)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)          // allows unlimited lines
                                .fixedSize(horizontal: false, vertical: true)

                            WMFYearInReviewScrollView(scrollViewContents: scrollViewContents, forceBackgroundColor: WMFColor.gray100)
                                .frame(minHeight: 0, maxHeight: dynamicMaxInfoboxHeight(availableHeight: geometry.size.height), alignment: .top)
                            .fixedSize(horizontal: false, vertical: true)
                            .overlay(
                                Rectangle().stroke(Color(WMFColor.gray300), lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: 324)
                        .padding([.leading, .trailing], 35)
                        
                        WMFLargeButton(configuration: .primary,
                                       title: viewModel.localizedStrings.buttonTitle,
                                       forceBackgroundColor: WMFColor.blue600) {
                            withAnimation(.easeInOut(duration: 0.75)) {
                                viewModel.tappedShare()
                            }
                        }
                        .frame(maxWidth: 345)
                        .padding([.leading, .trailing], 24)
                        
                    }
                    
                    Spacer(minLength: 0)
                }
            }
        }
        
    }
}

struct GradientBackgroundView: View {
    var body: some View {
        ZStack {
            // Base vertical gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 23/255,  green: 23/255,  blue: 23/255), location: 0.00),
                    .init(color: Color(red: 0/255,  green: 63/255,  blue: 69/255),location: 0.20),
                    .init(color: Color(red: 0/255, green: 128/255,  blue: 122/255),location: 0.40),
                    .init(color: Color(red: 42/255, green: 236/255, blue: 166/255),location: 0.60),
                    .init(color: Color(red: 134/255, green: 255/255, blue: 172/255),location: 0.80),
                    .init(color: .white, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Top black vignette (makes the top shadow darker)
            LinearGradient(
                colors: [.black.opacity(0.65), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.multiply)

            // Bottom glow
            LinearGradient(
                colors: [.white.opacity(0.18), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .blendMode(.screen)
        }
        .compositingGroup()
        .ignoresSafeArea()
    }
}
