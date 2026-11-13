import Foundation

// TODO: Still to be settled. Everything named "provisional" below is still to be confirmed: the event
// names, the `action_context` keys, the attempt outcomes and the trigger values. The `interleave_state`
// values come from US-4. The shapes follow the EF-3 acceptance criteria. The query attempt identifier
// and its counting rules are not defined yet.

/// How the list came out, as US-4 defines it. Only `full` lists count toward preference credit.
/// The control arm has no state: it shows today's list with no semantic request.
public enum WMFSemanticSearchInterleaveState: String, Sendable, Equatable, CaseIterable {
    /// Both retrievers answered and the lists were merged.
    case full
    /// The semantic request did not arrive within the timeout; the list is lexical only.
    case lexicalOnlyTimeout = "lexical_only_timeout"
    /// The semantic request failed or the backend was unavailable; the list is lexical only.
    case lexicalOnlyError = "lexical_only_error"
    /// The semantic request was rate limited; the list is lexical only.
    case lexicalOnlyRateLimited = "lexical_only_rate_limited"
    /// Semantic returned nothing and lexical returned results; the list is lexical only.
    /// Provisional: US-4 names no state for this case. Not a preference unit, since it has no
    /// semantic results. Still to be confirmed.
    case lexicalOnlyEmpty = "lexical_only_empty"
    /// Lexical returned nothing and semantic returned results.
    case semanticOnly = "semantic_only"
    /// Both returned nothing: the existing empty state shows.
    case none
}

/// What made the app request results. Provisional values.
public enum WMFSemanticSearchInterleavedTrigger: String, Sendable, Equatable {
    /// The reader paused typing.
    case pause
    /// The reader submitted the query.
    case submit
}

/// How a query attempt ended without a rendered list. Provisional values.
public enum WMFSemanticSearchInterleavedAttemptOutcome: String, Sendable, Equatable {
    /// The reader left, or cleared the query, before the minimum length or before a request.
    case endedBeforeRequest = "ended_before_request"
    /// Further typing or navigation replaced the request.
    case superseded
    /// The retrieval failed and no list rendered.
    case retrievalFailure = "retrieval_failure"
}

/// What the events of a query attempt log about the attempt, before there is a list.
public struct WMFSemanticSearchInterleavedAttemptLog: Sendable, Equatable {
    public let attemptID: String
    public let query: String
    /// The wiki of the search, like `frwiki`.
    public let wiki: String
    public let deviceLanguage: String
    /// `control` or `treatment`.
    public let arm: String

    public init(attemptID: String, query: String, wiki: String, deviceLanguage: String, arm: String) {
        self.attemptID = attemptID
        self.query = query
        self.wiki = wiki
        self.deviceLanguage = deviceLanguage
        self.arm = arm
    }
}

/// The search IDs from the response headers of the three requests. Analytics looks them up to
/// rebuild the lists the merge worked with.
public struct WMFSemanticSearchInterleavedIDs: Sendable, Equatable {
    public let prefix: String?
    public let fullText: String?
    public let semantic: String?

    public init(prefix: String?, fullText: String?, semantic: String?) {
        self.prefix = prefix
        self.fullText = fullText
        self.semantic = semantic
    }
}

public struct WMFSemanticSearchInterleavedLatency: Sendable, Equatable {
    public let lexicalMs: Int?
    public let semanticMs: Int?
    public let mergeMs: Int
    public let totalMs: Int

    public init(lexicalMs: Int?, semanticMs: Int?, mergeMs: Int, totalMs: Int) {
        self.lexicalMs = lexicalMs
        self.semanticMs = semanticMs
        self.mergeMs = mergeMs
        self.totalMs = totalMs
    }
}

/// What a rendered list logs once, for the list as a whole.
public struct WMFSemanticSearchInterleavedListLog: Sendable, Equatable {
    /// TODO: The list ID is a random UUID per rendered list for now. How it is generated and its format
    /// are not defined yet, so this still needs to be settled.
    public let listID: String
    /// Links the list to the query attempt it answers. Provisional: the identifier and the
    /// counting rules are still to be defined.
    public let attemptID: String
    public let query: String
    /// The wiki of the search, like `frwiki`.
    public let wiki: String
    public let deviceLanguage: String
    /// `control` or `treatment`.
    public let arm: String
    /// Nil when the list was not merged, as in the control arm.
    public let mergeVersion: Int?
    public let lexicalVersion: Int
    /// The seed as an unsigned decimal string, as in `WMFInterleaveResult.seedLog`. Nil when not merged.
    public let seed: String?
    /// The coin flips as a string of `L` and `S`, as in `WMFInterleaveResult.coinFlipsLog`. Nil when not merged.
    public let coinFlips: String?
    public let listLength: Int
    /// Nil in the control arm.
    public let interleaveState: WMFSemanticSearchInterleaveState?
    public let trigger: WMFSemanticSearchInterleavedTrigger
    public let latency: WMFSemanticSearchInterleavedLatency
    public let searchIDs: WMFSemanticSearchInterleavedIDs
    public let semanticModel: String?
    public let semanticIndexVersion: String?

    public init(listID: String, attemptID: String, query: String, wiki: String, deviceLanguage: String, arm: String, mergeVersion: Int?, lexicalVersion: Int, seed: String?, coinFlips: String?, listLength: Int, interleaveState: WMFSemanticSearchInterleaveState?, trigger: WMFSemanticSearchInterleavedTrigger, latency: WMFSemanticSearchInterleavedLatency, searchIDs: WMFSemanticSearchInterleavedIDs, semanticModel: String?, semanticIndexVersion: String?) {
        self.listID = listID
        self.attemptID = attemptID
        self.query = query
        self.wiki = wiki
        self.deviceLanguage = deviceLanguage
        self.arm = arm
        self.mergeVersion = mergeVersion
        self.lexicalVersion = lexicalVersion
        self.seed = seed
        self.coinFlips = coinFlips
        self.listLength = listLength
        self.interleaveState = interleaveState
        self.trigger = trigger
        self.latency = latency
        self.searchIDs = searchIDs
        self.semanticModel = semanticModel
        self.semanticIndexVersion = semanticIndexVersion
    }
}

/// What the app knows about a result that the merge does not: the page, the section it matched, its
/// score, how it was presented and whether it was on screen.
public struct WMFSemanticSearchInterleavedResultDetails: Sendable, Equatable {
    public let pageID: Int
    public let section: String?
    public let score: Double?
    /// The display format of the card (US-2): what the descriptor is, `lead` or `passage`.
    public let descriptorType: String?
    /// The display format of the card (US-2): whether a thumbnail is shown.
    public let hasThumbnail: Bool?
    /// Whether the result was on screen. Nil when the screen does not track it.
    public let isVisible: Bool?

    public init(pageID: Int, section: String?, score: Double?, descriptorType: String?, hasThumbnail: Bool?, isVisible: Bool?) {
        self.pageID = pageID
        self.section = section
        self.score = score
        self.descriptorType = descriptorType
        self.hasThumbnail = hasThumbnail
        self.isVisible = isVisible
    }
}

/// What a rendered list logs for each of its results.
public struct WMFSemanticSearchInterleavedResultLog: Sendable, Equatable {
    /// 1-based position in the merged list.
    public let position: Int
    public let team: WMFInterleaveSearchType
    /// 1-based rank in the result's own retriever, as the merge defines it.
    public let rank: Int
    public let alsoInOther: Bool
    public let details: WMFSemanticSearchInterleavedResultDetails

    public init(position: Int, team: WMFInterleaveSearchType, rank: Int, alsoInOther: Bool, details: WMFSemanticSearchInterleavedResultDetails) {
        self.position = position
        self.team = team
        self.rank = rank
        self.alsoInOther = alsoInOther
        self.details = details
    }
}

public extension WMFInterleaveResult {

    /// The per-result log of the merged list, in list order. `details` supplies what only the app
    /// knows about each result.
    func resultLogs(details: (WMFInterleaveSlot<Item>) -> WMFSemanticSearchInterleavedResultDetails) -> [WMFSemanticSearchInterleavedResultLog] {
        slots.enumerated().map { index, slot in
            WMFSemanticSearchInterleavedResultLog(position: index + 1, team: slot.searchType, rank: slot.rank, alsoInOther: slot.alsoInOther, details: details(slot))
        }
    }
}
