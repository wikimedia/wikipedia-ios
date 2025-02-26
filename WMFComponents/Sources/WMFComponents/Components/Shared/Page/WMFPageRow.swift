import SwiftUI

/// A reusable component for displaying a page row (typically an article) with swipe actions. These should be embedded inside of a List.
struct WMFPageRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    let id: String
    let titleHtml: String
    let articleDescription: String?
    let imageURL: URL?
    let isSaved: Bool
    let deleteItemAction: () -> Void
    let shareItemAction: () -> Void
    let saveOrUnsaveItemAction: () -> Void
    // TODO: get accessibility labels

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleHtml)
                    .font(Font(WMFFont.for(.callout)))
                    .foregroundColor(Color(theme.text))

                if let description = articleDescription {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(theme.secondaryText))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Color.clear
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.vertical, 8)
        .swipeActions {
            Button {
                deleteItemAction()
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .trash) ?? UIImage())
                    .accessibilityLabel("Delete")
            }
            .tint(Color(theme.destructive))
            .labelStyle(.iconOnly)

            Button {
                shareItemAction()
            } label: {
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .share) ?? UIImage())
                    .accessibilityLabel("Share")
            }
            .tint(Color(theme.secondaryAction))
            .labelStyle(.iconOnly)

            Button {
                saveOrUnsaveItemAction()
            } label: {
                if isSaved {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .bookmark) ?? UIImage())
                        .accessibilityLabel("Save")
                } else {
                    Image(uiImage: WMFSFSymbolIcon.for(symbol: .bookmarkFill) ?? UIImage())
                        .accessibilityLabel("Unsave")
                }
            }
            .tint(Color(theme.link))
            .labelStyle(.iconOnly)
        }
    }
}
