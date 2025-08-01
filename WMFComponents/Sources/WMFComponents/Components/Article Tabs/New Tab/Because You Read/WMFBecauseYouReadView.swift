import SwiftUI
import WMFData

struct WMFBecauseYouReadView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    var viewModel: WMFBecauseYouReadViewModel

    private var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 12) {
                if let string = viewModel.getSeedArticle().imageURLString, let url = URL(string: string) {
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
                    Text(viewModel.becauseYouReadTitle)
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

            VStack(spacing: 0) {
                ForEach(viewModel.loadItems(), id: \.id) { item in
                    rowView(item: item)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func rowView(item: HistoryItem) -> some View {
        ZStack {
            WMFPageRow(
                id: String(item.id),
                titleHtml: item.titleHtml,
                articleDescription: item.description,
                imageURLString: item.imageURLString,
                isSaved: item.isSaved,
                deleteAccessibilityLabel: nil,
                shareAccessibilityLabel: nil,
                saveAccessibilityLabel: nil,
                unsaveAccessibilityLabel: nil,
                showsSwipeActions: false,
                deleteItemAction: nil,
                shareItemAction: nil,
                saveOrUnsaveItemAction: nil,
                loadImageAction: { imageURLString in
                    return try? await viewModel.loadImage(imageURLString: imageURLString)
                }
            )
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .containerShape(Rectangle())
            .onTapGesture {
                viewModel.onTap(item)
            }
        }
        .contextMenu {
            Button {
                viewModel.onTap(item)
            } label: {
                Text(viewModel.openButtonTitle)
                Image(uiImage: WMFSFSymbolIcon.for(symbol: .chevronForward) ?? UIImage())
            }
        } preview: {
            WMFArticlePreviewView(viewModel: getPreviewViewModel(from: item))
        }
    }

    private func getPreviewViewModel(from item: HistoryItem) -> WMFArticlePreviewViewModel {
        return WMFArticlePreviewViewModel(
            url: item.url,
            titleHtml: item.titleHtml,
            description: item.description,
            imageURLString: item.imageURLString,
            isSaved: item.isSaved,
            snippet: item.snippet
        )
    }
}
