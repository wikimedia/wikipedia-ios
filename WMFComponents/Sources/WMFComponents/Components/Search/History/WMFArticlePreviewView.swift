import SwiftUI
import WMFData

struct WMFArticlePreviewView: View {
    let item: HistoryItem

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            if let url = item.imageURL {
                AsyncImage(url: url) { result in // fix loading
                    switch result {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 150)
                            .clipped()
                    case .failure:
                        EmptyView()
                            .frame(height: 0)
                            .foregroundColor(.clear)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            Text(item.titleHtml)
                .font(.headline)
                .foregroundColor(.white)


            if let description = item.description, !description.isEmpty { // article description
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }

            if let summary = item.description, !summary.isEmpty { // article summary
                Text(summary)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}


