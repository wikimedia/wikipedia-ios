@objc public final class SearchFunnel: NSObject {
    @objc static let shared = SearchFunnel()

    private var _searchSessionToken: String?

    var searchSessionToken: String? {
        if _searchSessionToken == nil {
           _searchSessionToken = UUID().uuidString
        }
        return _searchSessionToken
    }

    public enum Action: String, Codable {
        case start
        case results
        case didYouMean = "didyoumean"
        case autoSwitch = "autoswitch"
        case error
        case click
        case cancel
        case langSwitch = "langswitch"
    }

    public struct Event: EventInterface {
        public static let schema: EventPlatformClient.Schema = .search
        let action: Action
        let source: String
        let position: Int?
        let search_type: String?
        let number_of_results: Int?
        let time_to_display_results: Int?
        let session_token: String
    }

    func logEvent(action: Action, source: String, position: Int? = nil, searchType: WMFSearchType? = nil, numberOfResults: Int? = nil, timeToDisplay: Int? = nil) {
        guard let searchSessionToken else { return }
        let event = Event(action: action, source: source, position: position, search_type: searchType?.rawValue, number_of_results: numberOfResults, time_to_display_results: timeToDisplay, session_token: searchSessionToken)
        EventPlatformClient.shared.submit(stream: .search, event: event)
    }

    func logSearchStart(source: String) {
        _searchSessionToken = nil
        logEvent(action: .start, source: source)
    }

    func logSearchAutoSwitch(source: String) {
        logEvent(action: .autoSwitch, source: source)
    }

    func logSearchDidYouMean(source: String) {
        logEvent(action: .didYouMean, source: source)
    }

    func logSearchResultTap(position: Int, source: String) {
        logEvent(action: .click, source: source, position: position)
    }

    func logSearchCancel(source: String) {
        logEvent(action: .click, source: source)
    }

    func logSearchLangSwitch(source: String) {
        logEvent(action: .langSwitch, source: source)
    }

    func logSearchResults(with type: WMFSearchType, resultCount: Int, elapsedTime: Double, source: String) {
        logEvent(action: .results, source: source, searchType: type, numberOfResults: resultCount, timeToDisplay: Int(elapsedTime))
    }

    func logShowSearchError(with type: WMFSearchType, elapsedTime: Double, source: String) {
        logEvent(action: .error, source: source, searchType: type, timeToDisplay: Int(elapsedTime))
    }

}

public enum WMFSearchType: String, Codable {
    case full
    case prefix
}
