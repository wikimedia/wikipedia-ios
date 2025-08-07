import WMF

final class ArticleTabsFunnel {

    static let shared = ArticleTabsFunnel()

    public enum Action: String {
        case impression = "impression"
        case articleClick = "article_click"
        case closeFeedback = "feedback_close_click"
        case submitFeedback = "feedback_submit_click"
        case iconClick = "icon_click"
        case newTabClick = "new_tab_click"
        case newTabClickBackground = "new_tab_click_background"
        case continueClick = "continue_click"
        case learnClick = "learn_click"
        case resultClick = "result_click"
        case recommendationPrefClick = "rec_click"
        case didYouKnowPrefClick = "dyk_click"
        case tabsSettingsClick = "tabs_click"
        case screenshot = "screenshot"
    }

    public enum ActiveInterface: String {
        case icon = "tab_icon"
        case tooltip = "tab_tooltip"
        case overview = "tabs_overview"
        case feedback = "tabs_feedback"
        case articleMenu = "article_background_menu"
        case feed = "feed"
        case article = "article"
        case places = "places"
        case saved = "saved"
        case history = "history"
        case search = "search"
        case announcement = "tab_announce"
        case tabSearch = "tab_search"
        case tabsPreferences = "tabs_prefs"
        case settings = "setting"
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

        let event = ArticleTabsFunnel.Event(activeInterface: activeInterface?.rawValue, action: action?.rawValue, actionData: actionDataString, platform: "ios", wikiID: project?.notificationsApiWikiIdentifier)
        EventPlatformClient.shared.submit(stream: .appTabsInteraction, event: event)
    }

    func logTabIconFirstImpression(project: WikimediaProject) {
        logEvent(activeInterface: .icon, action: .impression, project: project)
    }

    func logTabTooltipImpression(project: WikimediaProject) {
        logEvent(activeInterface: .tooltip, action: .impression, project: project)
    }

    func logTabsOverviewImpression() {
        logEvent(activeInterface: .overview, action: .impression, project: nil)
    }

    func logArticleClick(project: WikimediaProject) {
        logEvent(activeInterface: .overview, action: .articleClick, project: project)
    }

    func logFeedbackClose() {
        logEvent(activeInterface: .feedback, action: .closeFeedback, project: nil)
    }

    func logFeedbackSubmit(selectedItems: [String], comment: String?) {
        let selectedJoined = selectedItems.filter { $0 != "other" }.joined(separator: ",")
        var actionData = [
            "feedback_select": selectedJoined
        ]

        if let comment {
            actionData["feedback_comment"] = comment
        }
        logEvent(activeInterface: .feedback, action: .submitFeedback, actionData: actionData, project: nil)
    }

    func logFeedbackImpression() {
        logEvent(activeInterface: .feedback, action: .impression, project: nil)
    }

    func logIconImpression(interface: ArticleTabsFunnel.ActiveInterface, project: WikimediaProject?) {
        logEvent(activeInterface: interface, action: .impression, project: project)
    }

    func logIconClick(interface: ArticleTabsFunnel.ActiveInterface, project: WikimediaProject?) {
        logEvent(activeInterface: interface, action: .articleClick, project: project)
    }

    func logGroupAssignment(group: String) {
        logEvent(activeInterface: nil, action: .impression, actionData: ["group": group], project: nil)
    }

    func logAddNewBlankTab() {
        logEvent(activeInterface: .overview, action: .newTabClick, project: nil)
    }

    func logOpenArticleInNewTab() {
        logEvent(activeInterface: .articleMenu, action: .newTabClick, project: nil)
    }

    func logOpenArticleInBackgroundTab() {
        logEvent(activeInterface: .articleMenu, action: .newTabClickBackground, project: nil)
    }

    func logAnnouncementClick(action: ArticleTabsFunnel.Action) {
        logEvent(activeInterface: .announcement, action: action)
    }

    func logAnnouncementImpression() {
        logEvent(activeInterface: .announcement, action: .impression)
    }

    func logRecentSearchesClick() {
        logEvent(activeInterface: .tabSearch, action: .resultClick, actionData: ["result": "recent"])
    }

    func logBecauseYouReadClick() {
        logEvent(activeInterface: .tabSearch, action: .resultClick, actionData: ["result": "byr"])
    }

    func logDidYouKnowClick() {
        logEvent(activeInterface: .tabSearch, action: .resultClick, actionData: ["result": "dyk"])
    }

    func logTabsPreferenceClick(action: ArticleTabsFunnel.Action) {
        logEvent(activeInterface: .tabsPreferences, action: action)
    }

    func logTabsOverviewScreenshot() {
        logEvent(activeInterface: .overview, action: .screenshot)
    }

}
