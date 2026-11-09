import Foundation
import Testing
@testable import WMFComponents

@MainActor
@Suite
struct WMFImageCollageViewModelTests {

    private func makeImageURLs(count: Int) -> [URL] {
        (0..<count).compactMap { URL(string: "https://upload.wikimedia.org/image-\($0).jpg") }
    }

    @Test
    func theCollageAlwaysHasSixTilesInTwoRowsOfThree() {
        let viewModel = WMFImageCollageViewModel(imageURLs: [])

        #expect(viewModel.layout == .header)
        #expect(viewModel.tiles.count == 6)
        #expect(viewModel.rows.count == 2)
        #expect(viewModel.rows.allSatisfy { $0.count == 3 })
        #expect(viewModel.rows.flatMap { $0 }.map(\.id) == [0, 1, 2, 3, 4, 5])
    }

    @Test
    func theEntryCardLayoutHasFourTilesInTwoRowsOfTwo() {
        let imageURLs = makeImageURLs(count: 6)
        let viewModel = WMFImageCollageViewModel(imageURLs: imageURLs, layout: .entryCard)

        #expect(viewModel.tiles.count == 4)
        #expect(viewModel.rows.count == 2)
        #expect(viewModel.rows.allSatisfy { $0.count == 2 })
        #expect(viewModel.tiles.map(\.imageURL) == Array(imageURLs.prefix(4)))
        #expect(viewModel.layout.tileHeight == 64)
    }

    @Test
    func hasImagesIsTrueOnlyWithAtLeastOneImage() {
        #expect(WMFImageCollageViewModel(imageURLs: []).hasImages == false)
        #expect(WMFImageCollageViewModel(imageURLs: makeImageURLs(count: 1)).hasImages)
    }

    @Test
    func theFirstSixImagesFillTheTilesInOrder() {
        let imageURLs = makeImageURLs(count: 8)
        let viewModel = WMFImageCollageViewModel(imageURLs: imageURLs)

        #expect(viewModel.tiles.map(\.imageURL) == Array(imageURLs.prefix(6)))
    }

    @Test
    func tilesWithoutAnImageStayEmpty() {
        let imageURLs = makeImageURLs(count: 2)
        let viewModel = WMFImageCollageViewModel(imageURLs: imageURLs)

        #expect(viewModel.tiles.prefix(2).map(\.imageURL) == imageURLs)
        #expect(viewModel.tiles.dropFirst(2).allSatisfy { $0.imageURL == nil })
    }

    @Test
    func theHeaderTilesAlternateTheirTonesInACheckerboard() {
        let viewModel = WMFImageCollageViewModel(imageURLs: [])

        let expectedTones: [WMFImageCollageTileViewModel.PlaceholderTone] = [
            .neutral, .neutralSubtle, .neutral,
            .neutralSubtle, .neutral, .neutralSubtle
        ]
        #expect(viewModel.tiles.map(\.placeholderTone) == expectedTones)
    }

    @Test
    func theEntryCardTilesAlternateTheirTonesInACheckerboard() {
        let viewModel = WMFImageCollageViewModel(imageURLs: [], layout: .entryCard)

        let expectedTones: [WMFImageCollageTileViewModel.PlaceholderTone] = [
            .neutral, .paper,
            .paper, .neutral
        ]
        #expect(viewModel.tiles.map(\.placeholderTone) == expectedTones)
    }

    @Test
    func theEntryCardTonesContrastWithTheCardBackground() {
        let theme = WMFTheme.light

        for tone in WMFImageCollageViewModel.Layout.entryCard.placeholderTones {
            #expect(tone.color(for: theme) != theme.midBackground)
        }
    }

    @Test
    func thePlaceholderTonesMapToTheThemeBackgrounds() {
        let theme = WMFTheme.light

        #expect(WMFImageCollageTileViewModel.PlaceholderTone.neutral.color(for: theme) == theme.baseBackground)
        #expect(WMFImageCollageTileViewModel.PlaceholderTone.neutralSubtle.color(for: theme) == theme.midBackground)
        #expect(WMFImageCollageTileViewModel.PlaceholderTone.paper.color(for: theme) == theme.paperBackground)
    }

    @Test
    func everyCollageHasItsOwnIdentity() {
        let first = WMFImageCollageViewModel(imageURLs: [], layout: .entryCard)
        let second = WMFImageCollageViewModel(imageURLs: [], layout: .entryCard)

        #expect(first.id != second.id)
    }
}
