import Testing
import WMFComponents
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// A Rive text run that the app does not write keeps what it held before: the text of the
    /// last slide, or the copy inside the .riv. Nothing on the screen shows that the app missed
    /// a run, so each slide must write each run that it owns.
    ///
    /// A leading or trailing fragment can be empty, because the number can start or end the
    /// sentence. The number and the body copy cannot.
    @Test
    func everySlideWritesAllOfItsTextRuns() {
        for slide in factory.makeSlides() {
            let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

            #expect(byPath["headline1"] != nil, "\(slide.id) writes no headline1")
            #expect(byPath["headline2"] != nil, "\(slide.id) writes no headline2")
            #expect(byPath["bodyCopy"]?.isEmpty == false, "\(slide.id) has no body copy")
            #expect(byPath.count == 4, "\(slide.id) writes \(byPath.count) runs, expected 4")

            let numberPaths = Set(byPath.keys).subtracting(["headline1", "headline2", "bodyCopy"])
            #expect(numberPaths.count == 1, "\(slide.id) does not write exactly one number")
            for path in numberPaths {
                #expect(byPath[path]?.isEmpty == false, "\(slide.id) leaves \(path) empty")
            }
        }
    }

    /// The number run belongs to the artboard, not to the slide. A slide that names the run of
    /// another artboard draws nothing, and the load still reports success.
    @Test
    func theNumberRunMatchesTheArtboard() {
        let runForArtboard = ["frame1": "readDays", "frame2": "streakNumber"]

        for slide in factory.makeSlides() {
            guard let artboard = slide.animation?.artboardName else {
                #expect(Bool(false), "\(slide.id) has no artboard")
                continue
            }
            guard let expected = runForArtboard[artboard] else {
                #expect(Bool(false), "\(slide.id) uses unknown artboard \(artboard)")
                continue
            }
            let paths = Set(slide.text.keys.map(\.path))
            #expect(paths.contains(expected), "\(slide.id) on \(artboard) must write \(expected)")
        }
    }

    /// The pager keys `.scrollPosition(id:)` on the slide id. Two slides with one id stop the
    /// paging from resolving.
    @Test
    func slideIdsAreUnique() {
        let ids = factory.makeSlides().map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
    }
}
