import WMFData

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
        case error
        case click
        case cancel
        case langSwitch = "langswitch"
    }

    public struct Event: EventInterface {
        public static let schema: EventPlatformClient.Schema = .search
        let action: Action
        let action_data: String?
        let source: String
        let position: Int?
        let search_type: String?
        let number_of_results: Int?
        let time_to_display_results: Int?
        let session_token: String
        let wiki_id: String?
    }

    var searchLanguage: String? {
        let userDefaults = UserDefaults.standard
        let lang = userDefaults.wmf_currentSearchContentLanguageCode()
        return lang
    }

    func logEvent(action: Action, actionData: [String: String]? = nil, source: String, position: Int? = nil, searchType: WMFSearchType? = nil, numberOfResults: Int? = nil, timeToDisplay: Int? = nil, wikiId: String?) {
        guard let searchSessionToken else { return }

        var actionDataString: String? = nil
        if let actionData {
            actionDataString = ""
            for (key, value) in actionData {
                actionDataString?.append("\(key):\(value), ")
            }

            // remove last ", "
            if let finalActionDataString = actionDataString,
               finalActionDataString.count > 1 {
                actionDataString?.removeLast(2)
            }
        }

        let event = Event(action: action, action_data: actionDataString, source: source, position: position, search_type: searchType?.rawValue, number_of_results: numberOfResults, time_to_display_results: timeToDisplay, session_token: searchSessionToken, wiki_id: wikiId)
        EventPlatformClient.shared.submit(stream: .search, event: event)
    }

    func logSearchStart(source: String) {
        _searchSessionToken = nil
        logEvent(action: .start, source: source, wikiId: searchLanguage)
    }

    func logSearchDidYouMean(source: String) {
        logEvent(action: .didYouMean, source: source, wikiId: searchLanguage)
    }

    func logSearchResultTap(position: Int, source: String) {
        logEvent(action: .click, source: source, position: position, wikiId: searchLanguage)
    }

    func logSearchCancel(source: String) {
        logEvent(action: .cancel, source: source, wikiId: searchLanguage)
    }

    func logSearchLangSwitch(source: String) {
        logEvent(action: .langSwitch, source: source, wikiId: searchLanguage)
    }

    func logSearchResults(with type: WMFSearchType, resultCount: Int, elapsedTime: Double, source: String) {
        logEvent(action: .results, source: source, searchType: type, numberOfResults: resultCount, timeToDisplay: Int(elapsedTime * 1000), wikiId: searchLanguage)
    }

    func logShowSearchError(with type: WMFSearchType, elapsedTime: Double, source: String) {
        logEvent(action: .error, source: source, searchType: type, timeToDisplay: Int(elapsedTime * 1000), wikiId: searchLanguage)
    }

}

public enum WMFSearchType: String, Codable {
    case full
    case prefix
}
