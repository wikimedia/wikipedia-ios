import WMF

@objc final class ActivityTabFunnel: NSObject {
    
    @objc static let shared = ActivityTabFunnel()
    
    public enum Action: String {
        case impression = "impression"
        case launch = "launch"
        case continueClick = "continue_click"
        case learnClick = "learn_click"
        case articleClick = "article_click"
        case clearHistory = "clear_history_click"
        case problemClick = "problem_click"
        
    }
    
    public enum ActiveInterface: String {
        case activityTabStart = "activity_tab_start"
        case activityTab = "activity_tab"
        case overflowMenu = "activity_tab_overflow_menu"
    }
    
    private struct Event: EventInterface {
        static let schema: WMF.EventPlatformClient.Schema = .appInteraction
        
        let activeInterface: String?
        let action: String?
        let actionData: String?
        let platform: String
        let wikiID: String?
        
        enum CodingKeys: String, CodingKey {
            case activeInterface = "active_interface"
            case action = "action"
            case actionData = "action_data"
            case platform = "platform"
            case wikiID = "wiki_id"
        }
    }
    
    private func logEvent(activeInterface: ActiveInterface? = nil, action: Action? = nil, actionData: [String: String]? = nil, project: WikimediaProject? = nil) {
        var actionDataString: String? = nil
        if let actionData {
            actionDataString = ""
            for (key, value) in actionData {
                actionDataString?.append("\(key):\(value), ")
            }
            
            if let finalActionDataString = actionDataString,
               finalActionDataString.count > 1 {
                actionDataString?.removeLast(2)
            }
        }
        
        let event = ActivityTabFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .appActivityTab, event: event)
    }
    
    func logOnboardingDidAppear() {
        logEvent(activeInterface: .activityTabStart, action: .impression, project: nil)
    }
    
    func logOnboardingDidTapContinue() {
        logEvent(activeInterface: .activityTabStart, action: .continueClick, project: nil)
    }
    
    func logOnboardingDidTapLearnMore() {
        logEvent(activeInterface: .activityTabStart, action: .learnClick, project: nil)
    }
    
    func logGroupAssignment(group: String) {
        logEvent(activeInterface: nil, action: .launch, actionData: ["group": group], project: nil)
    }
    
    func logActivityTabImpressionState(empty: String) {
        logEvent(activeInterface: .activityTab, action: .impression, actionData: ["state": empty], project: nil)
    }
    
    func logActivityTabArticleTap() {
        logEvent(activeInterface: .activityTab, action: .articleClick, project: nil)
    }
    
    func logActivityTabOverflowMenuLearnMore() {
        logEvent(activeInterface: .overflowMenu, action: .learnClick, project: nil)
    }
    
    func logActivityTabOverflowMenuClearHistory() {
        logEvent(activeInterface: .overflowMenu, action: .clearHistory, project: nil)
    }
    
    func logActivityTabOverflowMenuProblem() {
        logEvent(activeInterface: .overflowMenu, action: .problemClick, project: nil)
    }
    
    /*
     func logTabsOverviewTappedDYK() {
         logEvent(activeInterface: .overview, action: .suggestedTabClick, actionData: ["suggested": "dyk"], project: nil)
     }
     */
}

