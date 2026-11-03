import Foundation
import UIKit
import WMFData

/// An image grid with three columns and two rows. The grid shows the first six images. The
/// other tiles show two alternating background tones.
@MainActor
final class WMFImageCollageViewModel: ObservableObject {

    static let columnCount = 3
    static let rowCount = 2
    static var tileCount: Int { columnCount * rowCount }
    /// The tiles keep this height on every device. Only their width follows the screen width.
    static let tileHeight: CGFloat = 134

    let tiles: [WMFImageCollageTileViewModel]

    init(imageURLs: [URL]) {
        let visibleImageURLs = Array(imageURLs.prefix(Self.tileCount))
        tiles = (0..<Self.tileCount).map { index in
            let imageURL = index < visibleImageURLs.count ? visibleImageURLs[index] : nil
            return WMFImageCollageTileViewModel(index: index, imageURL: imageURL)
        }
    }

    var rows: [[WMFImageCollageTileViewModel]] {
        stride(from: 0, to: tiles.count, by: Self.columnCount).map { start in
            Array(tiles[start..<min(start + Self.columnCount, tiles.count)])
        }
    }
}

@MainActor
final class WMFImageCollageTileViewModel: ObservableObject, Identifiable {

    /// The two background tones behind the tiles. A tile with no image, or whose image has not
    /// loaded yet, shows its tone. Even tiles use `neutral` and odd tiles use `neutralSubtle`,
    /// so empty tiles alternate the way the design does.
    enum PlaceholderTone: Equatable {
        case neutral
        case neutralSubtle

        func color(for theme: WMFTheme) -> UIColor {
            switch self {
            case .neutral:
                return theme.baseBackground
            case .neutralSubtle:
                return theme.midBackground
            }
        }
    }

    let id: Int
    let imageURL: URL?
    let placeholderTone: PlaceholderTone
    @Published var uiImage: UIImage?

    private var imageTask: Task<Void, Never>?

    init(index: Int, imageURL: URL?) {
        self.id = index
        self.imageURL = imageURL
        self.placeholderTone = index.isMultiple(of: 2) ? .neutral : .neutralSubtle
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
