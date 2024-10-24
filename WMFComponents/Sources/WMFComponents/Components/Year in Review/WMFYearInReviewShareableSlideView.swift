import SwiftUI

struct WMFYearInReviewShareableSlideView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var viewModel: WMFYearInReviewViewModel
    var slide: Int
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Image(viewModel.slides[slide].imageName, bundle: .module)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(viewModel.slides[slide].title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                    .foregroundStyle(Color(uiColor: theme.text))
                Text(viewModel.slides[slide].subtitle)
                    .font(Font(WMFFont.for(.title3)))
                    .foregroundStyle(Color(uiColor: theme.text))
            }
            .padding(28)
            Spacer()
            HStack {
                Image("globe", bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading) {
                    Text("#WikipediaYearinReview")
                        .font(Font(WMFFont.for(.boldTitle3)))
                        .foregroundStyle(Color(uiColor: theme.link))

                    if let username = viewModel.username {
                        Text("\(viewModel.localizedStrings.usernameTitle):\(username)")
                            .font(Font(WMFFont.for(.georgiaTitle3)))
                            .foregroundStyle(Color(uiColor: theme.text))
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(uiColor: theme.paperBackground))
            .cornerRadius(12)
            .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            .frame(height: 80)
        }
        .padding(.bottom, 70)
        .background(Color(uiColor: theme.paperBackground))
    }

}
