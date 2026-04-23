import WMF
import WMFComponents

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
        case surveyClose = "feedback_close_click"
        case surveySubmit = "feedback_submit_click"
        case loginClick = "login_click"
        case activityNavClick = "activity_nav_click"
        case customizeClick = "customize_click"
        case exploreClick = "explore_click"
        case makeEditClick = "make_edit_click"
    }
    
    public enum ActiveInterface: String {
        case activityTabStart = "activity_tab_start"
        case activityTab = "activity_tab"
        case overflowMenu = "activity_tab_overflow_menu"
        case survey = "activity_tab_feedback"
        case activityTabLogin = "activity_tab_login"
        case activityTabCustomize = "activity_tab_customize"
        case activityTabOff = "activity_tab_off"
        
        // areas where the activity tab bar button could be tapped
        case feed = "feed"
        case article = "article"
        case mainPage = "main_page"
        case places = "places"
        case saved = "saved"
        case search = "search"
        case settings = "settings"
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
    
    func logActivityTabSurveyImpression() {
        logEvent(activeInterface: .survey, action: .impression, project: nil)
    }
    
    func logActivityTabSurveyCancel() {
        logEvent(activeInterface: .survey, action: .surveyClose, project: nil)
    }
    
    func logActivityTabCustomizeClick() {
        logEvent(activeInterface: .overflowMenu, action: .customizeClick, project: nil)
    }
    
    func logExploreClick() {
        logEvent(activeInterface: .activityTab, action: .exploreClick, project: nil)
    }
    
    func logMakeEditClick() {
        logEvent(activeInterface: .activityTab, action: .makeEditClick, project: nil)
    }
    
    @MainActor
    func logActivityTabCustomizeExit(viewModel: WMFActivityTabCustomizeViewModel) {
        var actionData: [String: String] = [:]
        
        if viewModel.isLoggedIn {
            actionData["time_spent"] = viewModel.isTimeSpentReadingOn ? "on" : "off"
            actionData["reading_insight"] = viewModel.isReadingInsightsOn ? "on" : "off"
            actionData["editing_insight"] = viewModel.isEditingInsightsOn ? "on" : "off"
        } else {
            actionData["time_spent"] = "off"
            actionData["reading_insight"] = "off"
            actionData["editing_insight"] = "off"
        }
        
        actionData["timeline"] = viewModel.isTimelineOfBehaviorOn ? "on" : "off"
        
        let allOff = !viewModel.isTimeSpentReadingOn &&
                             !viewModel.isReadingInsightsOn &&
                             !viewModel.isEditingInsightsOn &&
                             !viewModel.isTimelineOfBehaviorOn

        let allOn = viewModel.isTimeSpentReadingOn &&
                             viewModel.isReadingInsightsOn &&
                             viewModel.isEditingInsightsOn &&
                             viewModel.isTimelineOfBehaviorOn
        if allOff || allOn {
            actionData["all"] = allOff ? "off" : "on"
        } 
        
        logEvent(activeInterface: .activityTabCustomize, action: .customizeClick, actionData: actionData, project: nil)
    }
    
    func logFeedbackSubmit(selectedItems: [String], comment: String?) {

        let selectedJoined = selectedItems.filter { $0 != "other" }.joined(separator: ",")
        var actionData = [
            "feedback_select": selectedJoined
        ]

        if let comment, !comment.isEmpty {
            actionData["feedback_comment"] = comment.replacingOccurrences(of: ",", with: "&comma;")
        }
        
        logEvent(activeInterface: .survey, action: .surveySubmit, actionData: actionData, project: nil)
    }
    
    func logLoginClick() {
        logEvent(activeInterface: .activityTabLogin, action: .loginClick, project: nil)
    }
    
    func logTabBarSelected(from activeInterface: ActiveInterface, action: Action) {
        guard action == .activityNavClick else { return }

        logEvent(activeInterface: activeInterface, action: action, actionData: nil, project: nil)
    }

    
    func logActivityTabOffImpression() {
        logEvent(activeInterface: .activityTabOff, action: .impression, project: nil)
    }
    
    func logActivityTabOffCustomizeClick() {
        logEvent(activeInterface: .activityTabOff, action: .customizeClick, project: nil)
    }
    
    func logActivityTabOffNavClick(from sourceInterface: ActiveInterface) {
        logEvent(activeInterface: sourceInterface, action: .activityNavClick, project: nil)
    }
}
