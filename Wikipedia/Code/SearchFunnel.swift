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
        case launch
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

    func logSearchStart(source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        _searchSessionToken = nil
        logEvent(action: .start, actionData: actionDataForAssignment(assignment), source: source, wikiId: searchLanguage)
    }

    func logSearchDidYouMean(source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .didYouMean, actionData: actionDataForAssignment(assignment), source: source, wikiId: searchLanguage)
    }

    func logSearchResultTap(position: Int, source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .click, actionData: actionDataForAssignment(assignment), source: source, position: position, wikiId: searchLanguage)
    }

    func logSearchCancel(source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .cancel, actionData: actionDataForAssignment(assignment), source: source, wikiId: searchLanguage)
    }

    func logSearchLangSwitch(source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .langSwitch, actionData: actionDataForAssignment(assignment), source: source, wikiId: searchLanguage)
    }

    func logSearchResults(with type: WMFSearchType, resultCount: Int, elapsedTime: Double, source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .results, actionData: actionDataForAssignment(assignment), source: source, searchType: type, numberOfResults: resultCount, timeToDisplay: Int(elapsedTime * 1000), wikiId: searchLanguage)
    }

    func logShowSearchError(with type: WMFSearchType, elapsedTime: Double, source: String, assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) {
        logEvent(action: .error, actionData: actionDataForAssignment(assignment), source: source, searchType: type, timeToDisplay: Int(elapsedTime * 1000), wikiId: searchLanguage)
    }
    
    func logDidAssignArticleSearchExperiment(assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment) {
        
        logEvent(action: .launch, actionData: actionDataForAssignment(assignment), source: "unknown", wikiId: nil)
    }
    
    private func actionDataForAssignment(_ assignment: WMFNavigationExperimentsDataController.ArticleSearchBarExperimentAssignment?) -> [String: String]? {
        
        guard let assignment else {
            return nil
        }
        
        let group: String
        switch assignment {
        case .control: group = "a"
        case .test: group = "b"
        }
        
        return ["group": group]
    }

}

public enum WMFSearchType: String, Codable {
    case full
    case prefix
}
