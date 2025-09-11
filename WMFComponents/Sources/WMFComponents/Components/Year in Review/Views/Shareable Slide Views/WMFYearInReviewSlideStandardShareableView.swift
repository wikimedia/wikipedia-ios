import SwiftUI

struct WMFYearInReviewSlideStandardShareableView: View {
    let viewModel: WMFYearInReviewSlideViewModelProtocol

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private func subtitleAttributedString(subtitle: String) -> AttributedString {
        return (try? AttributedString(markdown: subtitle)) ?? AttributedString(subtitle)
    }

    private let hashtag: String
    private let needsFormatting: Bool
    
    init(viewModel: WMFYearInReviewSlideViewModelProtocol, appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, hashtag: String, needsFormatting: Bool = false) {
        self.viewModel = viewModel
        self.appEnvironment = appEnvironment
        self.hashtag = hashtag
        self.needsFormatting = needsFormatting
    }
    
    private var attributedString: AttributedString {
        return (try? HtmlUtils.attributedStringFromHtml(viewModel.subtitle, styles: styles)) ?? AttributedString(viewModel.subtitle)
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.headline), italicsFont: WMFFont.for(.headline), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }

    var body: some View {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Image("W-share-logo", bundle: .module)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(theme.text))

                    ZStack {
                        Image(viewModel.gifName, bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .ignoresSafeArea()
                            .padding(.horizontal, 0)
                    }
                    .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.title)
                            .font(Font(WMFFont.for(.boldTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                            .foregroundStyle(Color(uiColor: theme.text))
                        if needsFormatting {
                            Text(subtitleAttributedString(subtitle: viewModel.subtitle))
                                .font(Font(WMFFont.for(.title3)))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .accentColor(Color(uiColor: theme.link))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(attributedString)
                                .font(Font(WMFFont.for(.title3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                                .foregroundStyle(Color(uiColor: theme.text))
                                .accentColor(Color(uiColor: theme.link))
                        }
                    }
                    .padding([.top, .horizontal], 28)
                    .padding(.bottom, 0)
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
            .background(Color(uiColor: theme.paperBackground))
            .frame(maxWidth: 402)
            .frame(minHeight: 847)
    }
}


public protocol WMFYearInReviewSlideViewModelProtocol {
    var gifName: String { get }
    var subtitle: String { get }
    var title: String { get }
}
