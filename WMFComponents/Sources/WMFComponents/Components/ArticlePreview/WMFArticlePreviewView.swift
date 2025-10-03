import SwiftUI
import WMFData

/// View to be used within SwiftUI `preview` modifier when previewing articles (e.g. when long-pressing)
struct WMFArticlePreviewView: View {
    let viewModel: WMFArticlePreviewViewModel

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.colorScheme) var colorScheme

    var theme: WMFTheme { appEnvironment.theme }

    var screenWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 380 : UIScreen.main.bounds.width
    }

    var body: some View {
        let width = screenWidth - 32
        let hasTopVisual = (viewModel.imageURL != nil) || (viewModel.image != nil && viewModel.backgroundImage != nil)
        let headerHeight = width * 0.5
        let finalHeight = hasTopVisual ? width : width / 2

        VStack(alignment: .leading, spacing: 0) {
            // 1) Single remote image header
            if let url = viewModel.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: headerHeight)
                            .background(Color.gray.opacity(0.2))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: headerHeight)
                            .clipped()
                    case .failure:
                        EmptyView().frame(height: 0)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let fg = viewModel.image, let bg = viewModel.backgroundImage {
                ZStack {
                    Image(uiImage: bg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: headerHeight)
                        .clipped()
                        .overlay(
                            Color.black.opacity(0.6)
                                .opacity(colorScheme == .dark ? 1 : 0)
                        )

                    Image(uiImage: fg)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 48)
                        .frame(width: width, height: headerHeight, alignment: .center)
                        .allowsHitTesting(false)
                }
            }

            VStack(alignment: .leading) {
                Text(viewModel.titleHtml)
                    .font(Font(WMFFont.for(.georgiaTitle3)))
                    .foregroundColor(Color(theme.text))
                    .padding([.leading, .trailing], 8)
                    .padding(.top, 16)

                if let description = viewModel.description, !description.isEmpty {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(theme.secondaryText))
                        .padding([.leading, .trailing], 8)
                        .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(theme.midBackground))
            .padding(0)

            if let summary = viewModel.snippet, !summary.isEmpty {
                Text(summary)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(theme.text))
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .padding(8)
            }

            Spacer()
        }
        .frame(width: width, height: finalHeight)
        .background(Color(theme.paperBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}
