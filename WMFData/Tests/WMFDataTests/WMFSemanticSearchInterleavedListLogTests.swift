import Foundation
import Testing
@testable import WMFData

@Suite
struct WMFSemanticSearchInterleavedListLogTests {

    private struct Page: Sendable { let id: Int }

    @Test
    func everyStateOfTheSpecGoesOutByItsName() {
        let names = WMFSemanticSearchInterleaveState.allCases.map(\.rawValue)
        #expect(names == ["full", "lexical_only_timeout", "lexical_only_error", "lexical_only_rate_limited", "lexical_only_empty", "semantic_only", "none"])
    }

    @Test
    func attemptOutcomesGoOutByTheirNames() {
        #expect(WMFSemanticSearchInterleavedAttemptOutcome.endedBeforeRequest.rawValue == "ended_before_request")
        #expect(WMFSemanticSearchInterleavedAttemptOutcome.superseded.rawValue == "superseded")
        #expect(WMFSemanticSearchInterleavedAttemptOutcome.retrievalFailure.rawValue == "retrieval_failure")
    }

    @Test
    func resultLogsFollowTheMergedListWithTeamRankAndOverlap() {
        // Page 2 is in both lists, so it is placed once and flagged as also in the other list.
        let merge = WMFSearchResultsInterleaver.merge(
            lexical: [Page(id: 1), Page(id: 2)],
            semantic: [Page(id: 2), Page(id: 3)],
            listLength: 10,
            seed: 7,
            pageID: { $0.id }
        )

        let logs = merge.resultLogs { slot in
            WMFSemanticSearchInterleavedResultDetails(pageID: slot.item.id, section: nil, score: nil, descriptorType: nil, hasThumbnail: nil, isVisible: true)
        }

        #expect(logs.count == merge.slots.count)
        for (index, log) in logs.enumerated() {
            let slot = merge.slots[index]
            #expect(log.position == index + 1)
            #expect(log.team == slot.searchType)
            #expect(log.rank == slot.rank)
            #expect(log.alsoInOther == slot.alsoInOther)
            #expect(log.details.pageID == slot.item.id)
        }
        #expect(logs.first { $0.details.pageID == 2 }?.alsoInOther == true)
    }
}
