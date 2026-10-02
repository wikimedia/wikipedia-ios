import Testing
import WMFComponents
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// Only the articles visited multiple times slide has real data so far. It always shows,
    /// in its full or its empty version, so Year in Review never opens with no slides.
    @Test
    func makesOnlyTheArticlesVisitedMultipleTimesSlide() {
        let slides = factory.makeSlides()

        #expect(slides.count == 1)
        #expect(["frame12", "frame12-empty"].contains(slides.first?.animation?.artboardName ?? ""))
        #expect(slides.first?.animation?.resourceName == "all_templates")
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test
    func theSlideWritesAllOfItsTextRuns() throws {
        let slide = try #require(factory.makeSlides().first)
        let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

        switch slide.animation?.artboardName {
        case "frame12-empty":
            #expect(byPath["headline"]?.isEmpty == false)
            #expect(byPath["bodyText"]?.isEmpty == false)
            #expect(slide.articleThumbnails.isEmpty)
        case "frame12":
            #expect(byPath["bodyText"]?.isEmpty == false)
            // An unused row is written as an empty string, so all three rows are always present.
            for number in 1...3 {
                #expect(byPath["articleTitle\(number)"] != nil, "row \(number) has no title")
                #expect(byPath["subTitle\(number)"] != nil, "row \(number) has no subtitle")
            }
        default:
            Issue.record("unexpected artboard \(slide.animation?.artboardName ?? "nil")")
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
