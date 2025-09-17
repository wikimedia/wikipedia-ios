import SwiftUI

struct WMFYearInReviewSlideMostReadDateV3ShareableView: View {
    let viewModel: WMFYearInReviewSlideMostReadDateV3ViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        return appEnvironment.theme
    }

    private let hashtag: String

    init(viewModel: WMFYearInReviewSlideMostReadDateV3ViewModel, appEnvironment: WMFAppEnvironment = WMFAppEnvironment.current, hashtag: String) {
        self.viewModel = viewModel
        self.appEnvironment = appEnvironment
        self.hashtag = hashtag
    }

    private var styles: HtmlUtils.Styles {
        return HtmlUtils.Styles(font: WMFFont.for(.headline), boldFont: WMFFont.for(.boldHeadline), italicsFont: WMFFont.for(.headline), boldItalicsFont: WMFFont.for(.title3), color: theme.text, linkColor: theme.link, lineSpacing: 3)
    }
    
    private func dateItemView(text: String, footer: String) -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(Font(WMFFont.for(.georgiaTitle3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
            Text(footer)
                .font(Font(WMFFont.for(.subheadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var body: some View {
            VStack(spacing: 16) {

                header()

                content()

                Spacer(minLength: 10)

                footer()
                
            }
            .background(Color(uiColor: theme.paperBackground))
            .frame(maxWidth: 402)
            .frame(minHeight: 847)
    }
    
    private func header() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("W-share-logo", bundle: .module)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color(theme.text))
                .padding(.top, 20)

            Image(viewModel.gifName, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .ignoresSafeArea()
                .padding(.horizontal, 0)
        }
    }
    
    private func content() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(Font(WMFFont.for(.boldTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                .foregroundStyle(Color(uiColor: theme.text))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 16) {
                
                dateItemView(text: viewModel.time, footer: viewModel.timeFooter)
                dateItemView(text: viewModel.day, footer: viewModel.dayFooter)
                dateItemView(text: viewModel.month, footer: viewModel.monthFooter)
            }
            .foregroundStyle(Color(uiColor: theme.text))
            
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 0)
    }
    
    private func footer() -> some View {
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
}
