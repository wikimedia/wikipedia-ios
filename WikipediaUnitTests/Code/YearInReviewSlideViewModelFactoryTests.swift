import Testing
import WMFComponents
import WMFData
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// Frames that use the `List` view model. Every other frame uses `DataTemplate`.
    private static let listArtboards: Set<String> = [
        "frame7", "frame9", "frame12", "frame12-empty", "frame15", "frame15-empty", "frame18"
    ]

    private static let templatePaths: Set<String> = ["headline", "data", "bodyCopy"]

    private static let listItemCount = 3

    private static let listPaths: Set<String> = {
        var paths: Set<String> = ["headline", "bodyText"]
        for number in 1...listItemCount {
            paths.insert("articleTitle\(number)")
            paths.insert("subTitle\(number)")
        }
        return paths
    }()

    private var allSlides: [WMFYearInReviewSlideViewModel] {
        factory.makeSlides(userDataState: .dataRich) + factory.makeSlides(userDataState: .lowData)
    }

    private static func isEmptyVersion(_ artboard: String) -> Bool {
        artboard.hasSuffix("-empty")
    }

    private static func textByPath(_ slide: WMFYearInReviewSlideViewModel) -> [String: String] {
        Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })
    }

    private func text(_ slide: WMFYearInReviewSlideViewModel, _ path: String) -> String? {
        slide.text.first { $0.key.path == path }?.value
    }

    // MARK: - Text

    /// A name the view model does not have draws nothing, and the load still reports success.
    /// So every name a slide writes must exist in its frame's view model.
    @Test
    func everySlideWritesOnlyNamesItsViewModelHas() {
        for slide in allSlides {
            guard let artboard = slide.animation?.artboardName else {
                Issue.record("\(slide.id) has no artboard")
                continue
            }

            let allowed = Self.listArtboards.contains(artboard) ? Self.listPaths : Self.templatePaths
            let unknown = Set(Self.textByPath(slide).keys).subtracting(allowed)
            #expect(unknown.isEmpty, "\(slide.id) on \(artboard) writes unknown names \(unknown.sorted())")
        }
    }

    /// Text the app does not write keeps the sample copy from the .riv, and nothing on screen
    /// shows that it was missed. So each template slide writes every field its frame uses. An empty
    /// version has no number, but it still writes an empty string for `data`, because the .riv
    /// would otherwise show its "initial value" text there.
    @Test
    func templateSlidesWriteAllTheirText() {
        for slide in allSlides {
            guard let artboard = slide.animation?.artboardName,
                  !Self.listArtboards.contains(artboard) else {
                continue
            }

            let text = Self.textByPath(slide)
            #expect(text["headline"]?.isEmpty == false, "\(slide.id) has no headline")
            #expect(text["bodyCopy"]?.isEmpty == false, "\(slide.id) has no body copy")

            if Self.isEmptyVersion(artboard) {
                #expect(text["data"] == "", "\(slide.id) is an empty version but does not clear data")
            } else {
                #expect(text["data"]?.isEmpty == false, "\(slide.id) has no data")
            }
        }
    }

    /// List items come in title and subtitle pairs, numbered from 1 with no gaps. A row with an
    /// empty title only comes after the rows that have one, because an unused row is written as an
    /// empty string, so it does not keep the copy inside the .riv. Empty versions show no items and
    /// no thumbnails.
    @Test
    func listSlidesWriteAHeadingAndWholeItems() {
        for slide in allSlides {
            guard let artboard = slide.animation?.artboardName,
                  Self.listArtboards.contains(artboard) else {
                continue
            }

            let text = Self.textByPath(slide)
            let hasHeading = text["headline"]?.isEmpty == false || text["bodyText"]?.isEmpty == false
            #expect(hasHeading, "\(slide.id) has no heading")

            let itemCount = (1...Self.listItemCount).filter { text["articleTitle\($0)"] != nil }.count

            if Self.isEmptyVersion(artboard) {
                #expect(itemCount == 0, "\(slide.id) is an empty version but writes \(itemCount) items")
                #expect(slide.articleThumbnails.isEmpty, "\(slide.id) is an empty version but has thumbnails")
                continue
            }

            #expect(itemCount > 0, "\(slide.id) writes no items")
            #expect(text["articleTitle1"]?.isEmpty == false, "\(slide.id) has an empty first item")

            var sawEmptyRow = false
            for number in 1...Self.listItemCount {
                let title = text["articleTitle\(number)"]
                let hasSubtitle = text["subTitle\(number)"] != nil
                #expect((title != nil) == hasSubtitle, "\(slide.id) item \(number) has a title or a subtitle but not both")
                #expect((title != nil) == (number <= itemCount), "\(slide.id) items are not numbered from 1 without gaps")

                guard let title else { continue }
                if title.isEmpty {
                    sawEmptyRow = true
                } else {
                    #expect(!sawEmptyRow, "\(slide.id) item \(number) has a title after an empty row")
                }
            }
        }
    }

    // MARK: - Animation

    /// Each frame has its own state machine, named after it. A slide that names another frame's
    /// state machine does not animate, and the load still reports success.
    @Test
    func eachSlideUsesItsFramesStateMachine() {
        for slide in allSlides {
            guard let animation = slide.animation, let artboard = animation.artboardName else {
                Issue.record("\(slide.id) has no animation")
                continue
            }

            #expect(animation.resourceName == "all_templates", "\(slide.id) uses \(animation.resourceName)")
            #expect(animation.stateMachineName == "\(artboard)-statemachine", "\(slide.id) on \(artboard) uses \(animation.stateMachineName ?? "no state machine")")
        }
    }

    /// Each template sets `isUIWhite` for the contrast of the controls above it, so every slide must read it.
    @Test
    func everySlideReadsTheContrastFlag() {
        for slide in allSlides {
            #expect(slide.lightContentFlag?.path == "isUIWhite", "\(slide.id)")
        }
    }

    /// Long copy can push the content past the bottom of the slide, so every slide limits the
    /// headline and the body copy, and both shrink together.
    @Test
    func everySlideLimitsItsCopy() {
        for slide in allSlides {
            let copy = slide.textFits.filter { $0.text.path != "data" }
            #expect(copy.map(\.fontSize.path) == ["headlineFontSize", "bodyCopyFontSize"], "\(slide.id)")
            #expect(Set(copy.compactMap(\.group)).count == 1, "\(slide.id)")
            #expect(copy.allSatisfy { $0.minimumScale == YearInReviewSlideViewModelFactory.copyMinimumScale }, "\(slide.id)")
        }
    }

    // MARK: - User data state

    /// Every state opens with the total articles slide, and always includes the articles visited
    /// multiple times slide, in its full or its empty version, so Year in Review never opens with no slides.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func opensWithTheTotalArticlesSlideAndIncludesTheArticlesVisitedMultipleTimes(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let artboards = factory.makeSlides(userDataState: userDataState).map { $0.animation?.artboardName ?? "nil" }

        #expect(["frame1", "frame1-empty"].contains(artboards.first ?? ""))
        #expect(artboards.contains { ["frame12", "frame12-empty"].contains($0) })
    }

    /// Until the collective frames exist, low data stands in with the empty versions.
    @Test
    func lowDataShowsOnlyEmptyVersions() {
        let slides = factory.makeSlides(userDataState: .lowData)
        #expect(!slides.isEmpty)

        for slide in slides {
            let artboard = slide.animation?.artboardName ?? ""
            #expect(Self.isEmptyVersion(artboard), "\(slide.id) on \(artboard) is not an empty version")
        }
    }

    /// The other half of the mapping: data rich readers get the full versions, not the empty ones.
    @Test
    func dataRichShowsFullVersions() {
        let slides = factory.makeSlides(userDataState: .dataRich)
        #expect(slides.contains { !Self.isEmptyVersion($0.animation?.artboardName ?? "") })
    }

    /// The developer settings can force the empty version of each personalized slide for a data-rich
    /// user. They show the same slides as low data.
    @Test
    func allEmptyStatesShowsTheSameSlidesAsLowData() {
        let forced = factory.makeSlides(userDataState: .dataRich, forcesAllEmptyStates: true).map { $0.animation?.artboardName ?? "nil" }
        let lowData = factory.makeSlides(userDataState: .lowData).map { $0.animation?.artboardName ?? "nil" }

        #expect(forced == lowData)
        #expect(forced.allSatisfy { Self.isEmptyVersion($0) })
    }

    // MARK: - Total articles

    @Test(arguments: [0, 2])
    func fewerThanThreeArticlesShowTheEmptyState(readCount: Int) {
        let slide = factory.totalArticlesSlide(readCount: readCount, topReadPercentage: nil, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1-empty")
        #expect(text(slide, "data") == "")
    }

    @Test
    func aReaderInTheTopFiftyPercentSeesTheirPercentage() throws {
        let slide = factory.totalArticlesSlide(readCount: 350, topReadPercentage: 50, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1")
        #expect(text(slide, "data") == "350")
        let bodyCopy = try #require(text(slide, "bodyCopy"))
        #expect(bodyCopy.contains("50%"))
        #expect(bodyCopy.contains("335"))
        #expect(slide.localizedStrings.accessibilityLabel?.contains("350") == true)
        #expect(slide.localizedStrings.accessibilityLabel?.contains(bodyCopy) == true)
    }

    /// The large number keeps to one line. The empty slide has no number, so it fits nothing.
    @Test
    func onlyTheFullSlideFitsTheNumber() {
        let full = factory.totalArticlesSlide(readCount: 350, topReadPercentage: 50, averageReadCount: 335)
        let empty = factory.totalArticlesSlide(readCount: 0, topReadPercentage: nil, averageReadCount: 335)

        let number = full.textFits.first { $0.text.path == "data" }
        #expect(number?.maximumLines == 1)
        #expect(number?.fontSize.path == "dataNumberFontSize")
        #expect(number?.lineHeight.path == "dataNumbersLineHeight")
        #expect(empty.textFits.contains { $0.text.path == "data" } == false)
    }

    @Test
    func theTopBucketKeepsItsFraction() throws {
        let slide = factory.totalArticlesSlide(readCount: 50000, topReadPercentage: 0.01, averageReadCount: 335)

        #expect(try #require(text(slide, "bodyCopy")).contains("0.01%"))
    }

    @Test
    func aReaderBelowTheTopFiftyPercentSeesNoPercentage() throws {
        let slide = factory.totalArticlesSlide(readCount: 3, topReadPercentage: nil, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1")
        #expect(text(slide, "data") == "3")
        #expect(try #require(text(slide, "bodyCopy")).contains("%") == false)
    }

    /// The pager keys `.scrollPosition(id:)` on the slide id. Two slides with one id stop the
    /// paging from resolving.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func slideIdsAreUnique(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let ids = factory.makeSlides(userDataState: userDataState).map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    // MARK: - Strings

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
    }
}
