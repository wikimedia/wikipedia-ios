import SwiftUI

struct WMFYearInReviewShareableSlideView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var slide: Int
    var slideImage: String
    var slideTitle: String
    var slideSubtitle: String
    var hashtag: String
    var username: String?

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Image(slideImage, bundle: .module)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(slideTitle)
                    .font(Font(WMFFont.for(.boldTitle1, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                    .foregroundStyle(Color(uiColor: theme.text))
                Text(slideSubtitle)
                    .font(Font(WMFFont.for(.title3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
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
                    Text(hashtag)
                        .font(Font(WMFFont.for(.boldTitle3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
                        .foregroundStyle(Color(uiColor: theme.link))

                    if let username {
                        Text(username)
                            .font(Font(WMFFont.for(.georgiaTitle3, compatibleWith: UITraitCollection(preferredContentSizeCategory: .medium))))
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
        .frame(width: 402, height: 847) // Fixed iPhone 16 size for iPad as well
    }

}
