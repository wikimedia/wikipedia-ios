import Testing
import WMFComponents
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// Only the total articles slide and the articles visited multiple times slide have real data so
    /// far. Each always shows, in its full or its empty version, so Year in Review never opens with no slides.
    @Test
    func makesTheTotalArticlesAndTheArticlesVisitedMultipleTimesSlides() {
        let slides = factory.makeSlides()

        #expect(slides.count == 2)
        #expect(["frame1", "frame1-empty"].contains(slides.first?.animation?.artboardName ?? ""))
        #expect(["frame12", "frame12-empty"].contains(slides.last?.animation?.artboardName ?? ""))
        #expect(slides.allSatisfy { $0.animation?.resourceName == "all_templates" })
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test
    func theSlidesWriteAllOfTheirTextRuns() throws {
        for slide in factory.makeSlides() {
            let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

            switch slide.animation?.artboardName {
            case "frame1-empty":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
            case "frame1":
                #expect(byPath["headline"]?.isEmpty == false)
                #expect(byPath["data"]?.isEmpty == false)
                #expect(byPath["bodyCopy"]?.isEmpty == false)
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
    }

    // MARK: - Total articles

    private func text(_ slide: WMFYearInReviewSlideViewModel, _ path: String) -> String? {
        slide.text.first { $0.key.path == path }?.value
    }

    @Test(arguments: [0, 2])
    func fewerThanThreeArticlesShowTheEmptyState(readCount: Int) {
        let slide = factory.totalArticlesSlide(readCount: readCount, topReadPercentage: nil, averageReadCount: 335)

        #expect(slide.animation?.artboardName == "frame1-empty")
        #expect(text(slide, "data") == nil)
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
