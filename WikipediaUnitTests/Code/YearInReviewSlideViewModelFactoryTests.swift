import Testing
import WMFComponents
import WMFData
@testable import Wikipedia

@MainActor
@Suite
struct YearInReviewSlideViewModelFactoryTests {

    private let factory = YearInReviewSlideViewModelFactory()

    /// Only the total articles slide and the articles visited multiple times slide have real data so
    /// far. Each always shows, in its full or its empty version, so Year in Review never opens with no slides.
    /// The other frames show mock data, from the cover to the end slide.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func makesAllTheFramesFromTheCoverToTheEnd(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let slides = factory.makeSlides(userDataState: userDataState)

        #expect(slides.count == 19)
        #expect(slides.first?.animation?.artboardName == "cover")
        #expect(["frame1", "frame1-empty"].contains(slides[1].animation?.artboardName ?? ""))
        #expect(["frame12", "frame12-empty"].contains(slides[11].animation?.artboardName ?? ""))
        #expect(slides.last?.animation?.artboardName == "end")
        #expect(slides.allSatisfy { $0.animation?.resourceName == "all_templates" })
    }

    /// The state machine of each frame has the name of the frame with "-statemachine" after it.
    @Test
    func eachSlideUsesTheStateMachineOfItsFrame() {
        let slides = factory.makeSlides(userDataState: .dataRich) + factory.makeSlides(userDataState: .lowData)

        for slide in slides {
            let artboard = slide.animation?.artboardName ?? "nil"
            #expect(slide.animation?.stateMachineName == "\(artboard)-statemachine")
        }
    }

    /// A Rive text run that the app does not write keeps the copy inside the .riv. Nothing on the
    /// screen shows that the app missed a run, so the slide must write each run that it owns.
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func theSlidesWriteAllOfTheirTextRuns(userDataState: WMFYearInReviewDataController.YiRUserDataState) throws {
        for slide in factory.makeSlides(userDataState: userDataState) {
            let byPath = Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })

            if slide.id.hasPrefix("mock-") {
                #expect(slide.text.values.contains { !$0.isEmpty }, "\(slide.id) writes no text")
                continue
            }

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

    /// Each frame that has an empty version in the templates file shows it. The other frames show
    /// their full version.
    private let emptyStateArtboards = [
        "cover", "frame1-empty", "frame2", "frame3", "frame4-empty", "frame5-empty", "frame6-empty", "frame7", "frame8", "frame9", "frame10",
        "frame12-empty", "frame13", "frame14-empty", "frame15-empty", "frame16-empty", "frame17", "frame18", "end"
    ]

    /// A low-data user sees the empty version of each slide, whatever data is stored.
    @Test
    func aLowDataUserSeesOnlyEmptySlides() {
        let artboards = factory.makeSlides(userDataState: .lowData).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == emptyStateArtboards)
    }

    /// The developer settings can force the empty version of each personalized slide for a data-rich user.
    @Test
    func allEmptyStatesShowsOnlyEmptySlides() {
        let artboards = factory.makeSlides(userDataState: .dataRich, forcesAllEmptyStates: true).map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == emptyStateArtboards)
    }

    /// The mock frames show their full version for a data-rich user.
    @Test
    func aDataRichUserSeesTheFullMockSlides() {
        let artboards = factory.makeSlides(userDataState: .dataRich)
            .filter { $0.id.hasPrefix("mock-") }
            .map { $0.animation?.artboardName ?? "nil" }

        #expect(artboards == [
            "cover", "frame2", "frame3", "frame4", "frame5", "frame6", "frame7", "frame8", "frame9", "frame10",
            "frame13", "frame14", "frame15", "frame16", "frame17", "frame18", "end"
        ])
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
    @Test(arguments: [WMFYearInReviewDataController.YiRUserDataState.dataRich, .lowData])
    func slideIdsAreUnique(userDataState: WMFYearInReviewDataController.YiRUserDataState) {
        let ids = factory.makeSlides(userDataState: userDataState).map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
    }
}
