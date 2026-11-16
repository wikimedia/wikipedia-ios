import Foundation
import UIKit
import WMFData

/// An image grid with no gaps. The grid shows the first images that fit its layout. The other
/// tiles show two background tones in a checkerboard.
@MainActor
final class WMFImageCollageViewModel: ObservableObject {

    /// The grid shape. The tiles keep their height on every device. Only their width follows the
    /// width the grid gets. The tones contrast with the background the grid sits on.
    struct Layout: Equatable {
        let columnCount: Int
        let rowCount: Int
        let tileHeight: CGFloat
        let placeholderTones: [WMFImageCollageTileViewModel.PlaceholderTone]

        var tileCount: Int { columnCount * rowCount }

        /// Three columns by two rows, the header of the Discover list screen.
        static let header = Layout(columnCount: 3, rowCount: 2, tileHeight: 134, placeholderTones: [.neutral, .neutralSubtle])
        /// Two columns by two rows, the thumbnail on the Discover entry card in the Saved tab. The
        /// card is painted `midBackground`, so its tiles use the two other backgrounds.
        static let entryCard = Layout(columnCount: 2, rowCount: 2, tileHeight: 64, placeholderTones: [.neutral, .paper])

        func placeholderTone(row: Int, column: Int) -> WMFImageCollageTileViewModel.PlaceholderTone {
            placeholderTones[(row + column) % placeholderTones.count]
        }
    }

    /// Changes with every instance, so a view that swaps collages rebuilds its tiles.
    let id = UUID()
    let layout: Layout
    let tiles: [WMFImageCollageTileViewModel]

    init(imageURLs: [URL], layout: Layout = .header) {
        self.layout = layout
        let visibleImageURLs = Array(imageURLs.prefix(layout.tileCount))
        tiles = (0..<layout.tileCount).map { index in
            let imageURL = index < visibleImageURLs.count ? visibleImageURLs[index] : nil
            let placeholderTone = layout.placeholderTone(row: index / layout.columnCount, column: index % layout.columnCount)
            return WMFImageCollageTileViewModel(index: index, imageURL: imageURL, placeholderTone: placeholderTone)
        }
    }

    /// True when at least one tile has an image to show.
    var hasImages: Bool {
        tiles.contains { $0.imageURL != nil }
    }

    var rows: [[WMFImageCollageTileViewModel]] {
        stride(from: 0, to: tiles.count, by: layout.columnCount).map { start in
            Array(tiles[start..<min(start + layout.columnCount, tiles.count)])
        }
    }
}

@MainActor
final class WMFImageCollageTileViewModel: ObservableObject, Identifiable {

    /// The background tones behind the tiles. A tile with no image, or whose image has not
    /// loaded yet, shows its tone. The layout picks two of them and alternates them in a
    /// checkerboard, the way the design does.
    enum PlaceholderTone: Equatable {
        case neutral
        case neutralSubtle
        case paper

        func color(for theme: WMFTheme) -> UIColor {
            switch self {
            case .neutral:
                return theme.baseBackground
            case .neutralSubtle:
                return theme.midBackground
            case .paper:
                return theme.paperBackground
            }
        }
    }

    let id: Int
    let imageURL: URL?
    let placeholderTone: PlaceholderTone
    @Published var uiImage: UIImage?

    private var imageTask: Task<Void, Never>?

    init(index: Int, imageURL: URL?, placeholderTone: PlaceholderTone) {
        self.id = index
        self.imageURL = imageURL
        self.placeholderTone = placeholderTone
    }

    func loadImageIfNeeded() {
        guard uiImage == nil, imageTask == nil, let imageURL else { return }
        imageTask = Task { [weak self] in
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: imageURL),
                  !Task.isCancelled else { return }
            self?.uiImage = UIImage(data: data)
        }
    }

    deinit {
        imageTask?.cancel()
    }
}
