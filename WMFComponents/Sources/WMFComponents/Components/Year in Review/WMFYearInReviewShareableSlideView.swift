import SwiftUI

struct WMFYearInReviewShareableSlideView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var viewModel: WMFYearInReviewViewModel
    var slide: Int
    var body: some View {
        //TODO: Font size
        //TODO: Smaller screens ?
        VStack {
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
            .padding(60)
            Spacer()
            HStack {
                Image("globe", bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .padding(.leading, 15)

                VStack(alignment: .leading) {
                    Text("#WikipediaYearinReview")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)

                    if let username = viewModel.username {
                        Text("User:\(username)") // TODO: Localize it
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                }
                .padding(.leading, 10)

                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .frame(height: 80)

            Spacer()
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }

}
