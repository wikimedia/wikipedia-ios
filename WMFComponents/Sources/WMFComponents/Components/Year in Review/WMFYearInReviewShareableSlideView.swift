import SwiftUI

struct WMFYearInReviewShareableSlideView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let imageName: String
    var altText: String
    var slideTitle: String
    var slideSubtitle: String
    var hashtag: String
    var isAttributedString: Bool
    
    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(slideSubtitle, styles: styles)) ?? AttributedString(slideSubtitle)
    }
    
    private var styles: HtmlUtils.Styles {
        if isAttributedString {
            return HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.headline), italicsFont: WMFFont.for(.headline), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
        } else {
            return HtmlUtils.Styles(font: WMFFont.for(.title3), boldFont: WMFFont.for(.title3), italicsFont: WMFFont.for(.title3), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Image("W-share-logo", bundle: .module)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(theme.text))

                    ZStack {
                        Image(imageName, bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea()
                            .padding(.horizontal, 0)
                    }
                    .padding(.top, 10)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(slideTitle)
                            .font(Font(WMFFont.for(.boldTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                            .foregroundStyle(Color(uiColor: theme.text))
                        Text(attributedString)
                            .font(Font(WMFFont.for(.title3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                            .foregroundStyle(Color(uiColor: theme.text))
                            .accentColor(Color(uiColor: theme.link))
                    }
                    .padding([.top, .horizontal], 28)
                    .padding(.bottom, isAttributedString ? 0 : 28)
                }

                Spacer(minLength: 10)

                HStack {
                    Image("globe", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                    VStack(alignment: .leading) {
                        Text(hashtag)
                            .font(Font(WMFFont.for(.boldTitle3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: theme.paperBackground))
                .cornerRadius(12)
                .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 24)
                .frame(height: 80)
                .padding(.bottom, 60)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color(uiColor: theme.paperBackground))
        }
        .frame(width: 402, height: 847)
    }
}
