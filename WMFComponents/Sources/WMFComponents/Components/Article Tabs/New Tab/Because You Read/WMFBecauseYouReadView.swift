import SwiftUI

struct WMFBecauseYouReadView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    var viewModel: WMFBecauseYouReadViewModel

    private var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        HStack(spacing: 12) {
            if let url = viewModel.getSeedArticle().imageURL {
                AsyncImage(url: url) { img in
                    img.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.clear
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.becauseYouReadText)
                    .font(Font(WMFFont.for(.semiboldSubheadline)))
                    .foregroundColor(Color(theme.secondaryText))
                Text(viewModel.seedArticle.title)
                    .font(Font(WMFFont.for(.georgiaTitle3)))
                    .foregroundColor(Color(theme.text))
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(theme.midBackground))
    }
}
