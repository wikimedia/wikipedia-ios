import SwiftUI

/// Three columns by two rows of images, edge to edge and with no gaps. A list screen can show
/// it as the header behind a transparent navigation bar.
struct WMFImageCollageView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFImageCollageViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.rows, id: \.first?.id) { row in
                HStack(spacing: 0) {
                    ForEach(row) { tile in
                        WMFImageCollageTileView(viewModel: tile, theme: appEnvironment.theme)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct WMFImageCollageTileView: View {

    @ObservedObject var viewModel: WMFImageCollageTileViewModel
    let theme: WMFTheme

    var body: some View {
        Color(uiColor: viewModel.placeholderTone.color(for: theme))
            .frame(maxWidth: .infinity)
            .frame(height: WMFImageCollageViewModel.tileHeight)
            .overlay {
                if let uiImage = viewModel.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .onAppear {
                viewModel.loadImageIfNeeded()
            }
    }
}

#Preview("Six images") {
    WMFImageCollageView(viewModel: WMFImageCollageViewModel(imageURLs: WMFImageCollagePreviewData.imageURLs))
}

#Preview("Two images") {
    WMFImageCollageView(viewModel: WMFImageCollageViewModel(imageURLs: Array(WMFImageCollagePreviewData.imageURLs.prefix(2))))
}

#Preview("No images") {
    WMFImageCollageView(viewModel: WMFImageCollageViewModel(imageURLs: []))
}

private enum WMFImageCollagePreviewData {
    static let imageURLs: [URL] = [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/960px-Cat_November_2010-1a.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/960px-Cat03.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Felis_catus-cat_on_snow.jpg/960px-Felis_catus-cat_on_snow.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/68/Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg/960px-Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Cat_August_2010-4.jpg/960px-Cat_August_2010-4.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Van_kitten.jpg/960px-Van_kitten.jpg"
    ].compactMap(URL.init(string:))
}
