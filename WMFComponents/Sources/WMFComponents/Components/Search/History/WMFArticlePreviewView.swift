import SwiftUI
import WMFData

struct WMFArticlePreviewView: View {
    let item: HistoryItem
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var screenWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 380
        } else {
            return UIScreen.main.bounds.width
        }
    }

    var body: some View {
        let width = screenWidth - 32
        let hasImage = item.imageURL != nil
        let finalHeight = hasImage ? width : width / 2

        VStack(alignment: .leading, spacing: 0) {
            if let url = item.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: width * 0.5)
                            .background(Color.gray.opacity(0.2))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width * 0.5)
                            .clipped()
                    case .failure:
                        EmptyView()
                            .frame(height: 0)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            VStack(alignment: .leading) {
                Text(item.titleHtml)
                    .font(Font(WMFFont.for(.georgiaTitle3)))
                    .foregroundColor(Color(theme.text))
                    .padding([.leading, .trailing], 8)
                    .padding(.top, 16)

                if let description = item.description, !description.isEmpty {
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

            if let summary = item.snippet, !summary.isEmpty {
                Text(summary)
                    .font(Font(WMFFont.for(.subheadline)))
                    .foregroundColor(Color(theme.text))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
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
