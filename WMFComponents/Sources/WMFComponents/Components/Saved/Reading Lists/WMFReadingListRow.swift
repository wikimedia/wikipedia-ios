import SwiftUI
import WMFData
import WMFNativeLocalizations

struct WMFReadingListRow: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFReadingListRowViewModel
    let isEditing: Bool
    let isSelected: Bool

    private let defaultListTag = CommonStrings.readingListsDefaultListTag
    private let defaultListTitle = CommonStrings.readingListsDefaultListTitle
    private let defaultListDescription = CommonStrings.readingListsDefaultListDescription
    private let listNotSynced = CommonStrings.readingListsListNotSyncedLimitExceeded
    private let articlesNotSynced = CommonStrings.readingListsArticlesNotSyncedLimitExceeded

    private let imageSide: CGFloat = 100

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isEditing && !viewModel.readingList.isDefault {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(uiColor: appEnvironment.theme.link) : Color(uiColor: appEnvironment.theme.secondaryText))
                    .font(.system(size: 22))
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.articleCountText)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))

                Text(title)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(uiColor: appEnvironment.theme.text))

                if let description, !description.isEmpty {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                }

                if let alertText {
                    HStack(spacing: 4) {
                        if let icon = WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangle, font: .semiboldCaption1) {
                            Image(uiImage: icon)
                        }
                        Text(alertText)
                            .font(Font(WMFFont.for(.semiboldCaption1)))
                    }
                    .foregroundColor(Color(uiColor: appEnvironment.theme.warning))
                    .padding(.top, 4)
                }

                if viewModel.readingList.isDefault {
                    Text(defaultListTag)
                        .font(Font(WMFFont.for(.italicCaption1)))
                        .foregroundColor(Color(uiColor: appEnvironment.theme.secondaryText))
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)

            images
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 124, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// The default list shows the localized "Saved" title and description, whatever its stored name.
    private var title: String {
        viewModel.readingList.isDefault ? defaultListTitle : viewModel.readingList.name
    }

    private var description: String? {
        viewModel.readingList.isDefault ? defaultListDescription : viewModel.readingList.description
    }

    private var alertText: String? {
        switch viewModel.readingList.alertType {
        case .listLimitExceeded:
            return listNotSynced
        case .entryLimitExceeded:
            return articlesNotSynced
        case .none:
            return nil
        }
    }

    /// Four thumbnails make a 2×2 grid; one to three show the first; none shows nothing.
    @ViewBuilder
    private var images: some View {
        if viewModel.images.count == 4 {
            let cell = (imageSide - 2) / 2
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    thumbnail(viewModel.images[0], side: cell)
                    thumbnail(viewModel.images[1], side: cell)
                }
                HStack(spacing: 2) {
                    thumbnail(viewModel.images[2], side: cell)
                    thumbnail(viewModel.images[3], side: cell)
                }
            }
            .frame(width: imageSide, height: imageSide)
            .clipShape(RoundedRectangle(cornerRadius: 3))
        } else if let first = viewModel.images.first {
            thumbnail(first, side: imageSide)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }

    @ViewBuilder
    private func thumbnail(_ image: UIImage?, side: CGFloat) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: side, height: side)
                .clipped()
        } else {
            Color(uiColor: appEnvironment.theme.midBackground)
                .frame(width: side, height: side)
        }
    }
}

@MainActor
final class WMFReadingListRowViewModel: ObservableObject, Identifiable {
    let readingList: WMFReadingList
    /// One slot per preview thumbnail, nil while loading. Empty when the list has no thumbnails.
    @Published private(set) var images: [UIImage?]

    var id: String { readingList.id }

    private var loadTask: Task<Void, Never>?

    init(readingList: WMFReadingList) {
        self.readingList = readingList
        self.images = readingList.previewThumbnailURLs.isEmpty ? [] : Array(repeating: nil, count: readingList.previewThumbnailURLs.count)
        loadImages()
    }

    deinit {
        loadTask?.cancel()
    }

    var articleCountText: String {
        String.localizedStringWithFormat(CommonStrings.articleCountFormat, readingList.articleCount).uppercased()
    }

    private func loadImages() {
        let urls = readingList.previewThumbnailURLs
        guard !urls.isEmpty else { return }
        loadTask = Task { [weak self] in
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                for (index, url) in urls.enumerated() {
                    group.addTask {
                        (index, await UIImage.loadFaceCropped(from: url))
                    }
                }
                for await (index, image) in group {
                    guard let self, !Task.isCancelled else { return }
                    self.images[index] = image
                }
            }
        }
    }
}
