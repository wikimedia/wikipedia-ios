import Testing
import WMFComponents
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
        factory.makeSlides(for: .personalized) + factory.makeSlides(for: .collective)
    }

    private static func isEmptyVersion(_ artboard: String) -> Bool {
        artboard.hasSuffix("-empty")
    }

    private static func textByPath(_ slide: WMFYearInReviewSlideViewModel) -> [String: String] {
        Dictionary(uniqueKeysWithValues: slide.text.map { ($0.key.path, $0.value) })
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
    /// shows that it was missed. So each template slide writes every field its frame uses.
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
                #expect(text["data"] == nil, "\(slide.id) is an empty version but writes data")
            } else {
                #expect(text["data"]?.isEmpty == false, "\(slide.id) has no data")
            }
        }
    }

    /// List items come in title and subtitle pairs, numbered from 1 with no gaps. Empty versions
    /// show no items.
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
                continue
            }

            #expect(itemCount > 0, "\(slide.id) writes no items")
            for number in 1...Self.listItemCount {
                let hasTitle = text["articleTitle\(number)"] != nil
                let hasSubtitle = text["subTitle\(number)"] != nil
                #expect(hasTitle == hasSubtitle, "\(slide.id) item \(number) has a title or a subtitle but not both")
                #expect(hasTitle == (number <= itemCount), "\(slide.id) items are not numbered from 1 without gaps")
                if hasTitle {
                    #expect(text["articleTitle\(number)"]?.isEmpty == false, "\(slide.id) item \(number) has an empty title")
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

    // MARK: - Flows

    /// Until the collective frames exist, the collective flow stands in with the empty versions.
    @Test
    func theCollectiveFlowShowsOnlyEmptyVersions() {
        let slides = factory.makeSlides(for: .collective)
        #expect(!slides.isEmpty)

        for slide in slides {
            let artboard = slide.animation?.artboardName ?? ""
            #expect(Self.isEmptyVersion(artboard), "\(slide.id) on \(artboard) is not an empty version")
        }
    }

    /// The pager keys `.scrollPosition(id:)` on the slide id. Two slides with one id stop the
    /// paging from resolving.
    @Test(arguments: [YearInReviewCoordinator.Flow.personalized, .collective])
    func slideIdsAreUnique(flow: YearInReviewCoordinator.Flow) {
        let ids = factory.makeSlides(for: flow).map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate slide id in \(ids)")
    }

    // MARK: - Strings

    @Test
    func thePositionValueReadsAsOneBased() {
        let strings = factory.makeLocalizedStrings()
        #expect(strings.slidePositionAccessibilityValue(2, 5) == "2 of 5")
    }
}
