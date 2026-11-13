import Foundation

/// Follows one query attempt of the semantic search interleaved experiment and says which events to send
/// as the reader types, searches and leaves. Successive keystrokes of one attempt share the attempt ID.
///
/// TODO: Still to be settled. When an attempt starts and ends is provisional: the query attempt
/// identifier and its counting rules are not defined yet.
public struct WMFSemanticSearchInterleavedAttemptTracker: Sendable {

    /// An event to send for an attempt.
    public enum Step: Equatable, Sendable {
        case queryInput(attemptID: String)
        case retrievalEligible(attemptID: String)
        case attemptEnded(attemptID: String, outcome: WMFSemanticSearchInterleavedAttemptOutcome)
    }

    public private(set) var attemptID: String
    private var hasQueryInput = false
    private var hasEligibility = false
    private var hasRequested = false
    /// A list rendered or the attempt already ended, so nothing more ends it.
    private var isClosed = false
    private let makeID: @Sendable () -> String

    public init(makeID: @escaping @Sendable () -> String = { UUID().uuidString }) {
        self.makeID = makeID
        self.attemptID = makeID()
    }

    /// The reader typed a non-empty query. Typing after a request starts a new attempt.
    public mutating func queryChanged(length: Int, minimumLength: Int) -> [Step] {
        var steps: [Step] = []
        if hasRequested {
            steps += endOpenAttempt()
            startAttempt()
        }
        return steps + queryEvents(length: length, minimumLength: minimumLength)
    }

    /// The app is about to ask for results. A second request without typing replaces the first: a
    /// new attempt for the same text. A search with no typing, like a recent search, has its query
    /// events first.
    public mutating func requestIssued(length: Int, minimumLength: Int) -> [Step] {
        var steps: [Step] = []
        if hasRequested {
            steps += endOpenAttempt()
            startAttempt()
            steps += queryEvents(length: length, minimumLength: minimumLength)
        } else if !hasQueryInput {
            steps += queryEvents(length: length, minimumLength: minimumLength)
        }
        hasRequested = true
        return steps
    }

    /// The list rendered, so the attempt does not end without a list.
    public mutating func listRendered() {
        isClosed = true
    }

    /// No list rendered because the retrieval failed.
    public mutating func retrievalFailed() -> [Step] {
        guard !isClosed else { return [] }
        isClosed = true
        return [.attemptEnded(attemptID: attemptID, outcome: .retrievalFailure)]
    }

    /// The reader cleared the query or left the search. An attempt with input and no list ends here.
    public mutating func reset() -> [Step] {
        let steps = endOpenAttempt()
        startAttempt()
        return steps
    }

    // MARK: - Private

    private mutating func queryEvents(length: Int, minimumLength: Int) -> [Step] {
        hasQueryInput = true
        var steps: [Step] = [.queryInput(attemptID: attemptID)]
        if length >= minimumLength, !hasEligibility {
            hasEligibility = true
            steps.append(.retrievalEligible(attemptID: attemptID))
        }
        return steps
    }

    private mutating func endOpenAttempt() -> [Step] {
        guard hasQueryInput, !isClosed else { return [] }
        isClosed = true
        return [.attemptEnded(attemptID: attemptID, outcome: hasRequested ? .superseded : .endedBeforeRequest)]
    }

    private mutating func startAttempt() {
        attemptID = makeID()
        hasQueryInput = false
        hasEligibility = false
        hasRequested = false
        isClosed = false
    }
}
