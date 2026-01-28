import SwiftUI
import WMFData

struct WMFSavedArticleCell: View {

    @ObservedObject var viewModel: WMFSavedArticleCellViewModel
    let isEditing: Bool
    let isSelected: Bool
    let theme: WMFTheme
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isEditing {
                    selectionIndicator
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.semiboldHeadline)))
                        .foregroundColor(Color(uiColor: theme.text))
                        .lineLimit(2)

                    if let description = viewModel.description {
                        Text(description)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                            .lineLimit(1)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    if !viewModel.readingListNames.isEmpty {
                        readingListTags
                    }
                }

                Spacer()

                thumbnailView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .task {
            await viewModel.fetchArticleDetails()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isEditing {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }

                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(Color(uiColor: theme.link))
            }
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailURL = viewModel.thumbnailURL {
            AsyncImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(uiColor: theme.border)
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
        } else if viewModel.isLoading {
            Color(uiColor: theme.border)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
        }
    }

    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? Color(uiColor: theme.link) : Color(uiColor: theme.secondaryText))
            .font(.system(size: 22))
    }

    private var readingListTags: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.readingListNames.prefix(2), id: \.self) { listName in
                Text(listName)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(uiColor: theme.link))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: theme.link).opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}
