import Foundation
import Testing
@testable import WMFData

@Suite
struct WMFSemanticSearchInterleavedAttemptTrackerTests {

    private typealias Tracker = WMFSemanticSearchInterleavedAttemptTracker

    private final class IDs: @unchecked Sendable {
        private var count = 0
        func next() -> String { count += 1; return "id-\(count)" }
    }

    private func makeTracker() -> Tracker {
        let ids = IDs()
        return Tracker(makeID: { ids.next() })
    }

    @Test
    func keystrokesOfOneAttemptShareTheAttemptID() {
        var tracker = makeTracker()

        let first = tracker.queryChanged(length: 1, minimumLength: 3)
        let second = tracker.queryChanged(length: 2, minimumLength: 3)

        #expect(first == [.queryInput(attemptID: "id-1")])
        #expect(second == [.queryInput(attemptID: "id-1")])
    }

    @Test
    func eligibilityFiresOnceWhenTheQueryMeetsTheMinimumLength() {
        var tracker = makeTracker()

        _ = tracker.queryChanged(length: 2, minimumLength: 3)
        let atMinimum = tracker.queryChanged(length: 3, minimumLength: 3)
        let beyond = tracker.queryChanged(length: 4, minimumLength: 3)

        #expect(atMinimum == [.queryInput(attemptID: "id-1"), .retrievalEligible(attemptID: "id-1")])
        #expect(beyond == [.queryInput(attemptID: "id-1")])
    }

    @Test
    func typingAfterARequestSupersedesTheAttemptAndStartsANewOne() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 4, minimumLength: 3)
        _ = tracker.requestIssued(length: 4, minimumLength: 3)

        let steps = tracker.queryChanged(length: 5, minimumLength: 3)

        #expect(steps == [
            .attemptEnded(attemptID: "id-1", outcome: .superseded),
            .queryInput(attemptID: "id-2"),
            .retrievalEligible(attemptID: "id-2")
        ])
    }

    @Test
    func typingAfterARenderedListStartsANewAttemptWithoutEndingTheOldOne() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 4, minimumLength: 3)
        _ = tracker.requestIssued(length: 4, minimumLength: 3)
        tracker.listRendered()

        let steps = tracker.queryChanged(length: 5, minimumLength: 3)

        #expect(steps == [.queryInput(attemptID: "id-2"), .retrievalEligible(attemptID: "id-2")])
    }

    @Test
    func aSecondRequestWithoutTypingIsANewAttemptForTheSameText() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 4, minimumLength: 3)
        let first = tracker.requestIssued(length: 4, minimumLength: 3)

        let second = tracker.requestIssued(length: 4, minimumLength: 3)

        #expect(first.isEmpty)
        #expect(second == [
            .attemptEnded(attemptID: "id-1", outcome: .superseded),
            .queryInput(attemptID: "id-2"),
            .retrievalEligible(attemptID: "id-2")
        ])
    }

    @Test
    func leavingBeforeARequestEndsTheAttemptBeforeRequest() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 2, minimumLength: 3)

        let steps = tracker.reset()

        #expect(steps == [.attemptEnded(attemptID: "id-1", outcome: .endedBeforeRequest)])
        #expect(tracker.attemptID == "id-2")
    }

    @Test
    func leavingAfterARenderedListEndsNothing() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 4, minimumLength: 3)
        _ = tracker.requestIssued(length: 4, minimumLength: 3)
        tracker.listRendered()

        #expect(tracker.reset().isEmpty)
    }

    @Test
    func aFailedRetrievalEndsTheAttemptOnceAndNothingEndsItAgain() {
        var tracker = makeTracker()
        _ = tracker.queryChanged(length: 4, minimumLength: 3)
        _ = tracker.requestIssued(length: 4, minimumLength: 3)

        let failed = tracker.retrievalFailed()
        let again = tracker.retrievalFailed()
        let typing = tracker.queryChanged(length: 5, minimumLength: 3)

        #expect(failed == [.attemptEnded(attemptID: "id-1", outcome: .retrievalFailure)])
        #expect(again.isEmpty)
        #expect(typing.contains(.attemptEnded(attemptID: "id-1", outcome: .superseded)) == false, "A failed attempt is not superseded as well")
    }

    @Test
    func aSearchWithNoTypingSendsItsQueryEventsFirst() {
        var tracker = makeTracker()

        let steps = tracker.requestIssued(length: 5, minimumLength: 3)

        #expect(steps == [.queryInput(attemptID: "id-1"), .retrievalEligible(attemptID: "id-1")])
    }

    @Test
    func anAttemptWithNoInputEndsNothing() {
        var tracker = makeTracker()

        #expect(tracker.reset().isEmpty)
    }
}
