import SwiftUI

struct WMFYearInReviewSlideLocationShareableView: View {
    let viewModel: WMFYearInReviewSlideLocationViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private let hashtag: String
    
    init(viewModel: WMFYearInReviewSlideLocationViewModel, appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, hashtag: String) {
        self.viewModel = viewModel
        self.appEnvironment = appEnvironment
        self.hashtag = hashtag
    }
    
    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.body), boldFont: WMFFont.for(.boldBody), italicsFont: WMFFont.for(.body), boldItalicsFont: WMFFont.for(.body), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    private var mapView: Image {
        if let snapshotMapViewImage = viewModel.mapViewSnapshotForSharing {
            return Image(uiImage: snapshotMapViewImage)
        } else {
            return Image("")
        }
    }

    var body: some View {
            VStack(spacing: 16) {
                
                // header
                VStack(alignment: .leading, spacing: 16) {
                    Image("W-share-logo", bundle: .module)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(theme.text))
                        .padding(.top, 20)
                    
                    mapView
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea()
                        .padding(.horizontal, 0)
                        .padding(.top, 10)
                }
                
                // content
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .fixedSize(horizontal: false, vertical: true)
                    WMFHtmlText(html: viewModel.subtitle, styles: styles)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 0)
                
                Spacer(minLength: 10)

                // footer
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
