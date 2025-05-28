import WMF


final class ArticleTabsFunnel {

    static let shared = ArticleTabsFunnel()

    private enum Action: String {
        case impression = "impression"
        case click = "article_click"
        case closeFeedback = "feedback_close_click"
        case submitFeedback = "feedback_submit_click"
    }

    private enum ActiveInterface: String {
        case icon = "tab_icon"
        case tooltip = "tab_tooltip"
        case overview = "tabs_overview"
        case feedback = "tabs_feedback"
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

    func logTabIconImpression(project: WikimediaProject) {
        logEvent(activeInterface: .icon, action: .impression, project: project) // add to 1st tooltip because it only shows once
    }

    func logTabTooltipImpression(project: WikimediaProject) {
        logEvent(activeInterface: .tooltip, action: .impression, project: project)
    }

    func logTabsOverviewImpression(project: WikimediaProject) {
        logEvent(activeInterface: .overview, action: .impression, project: project)
    }

    func logArticleClick(project: WikimediaProject) {
        logEvent(activeInterface: .overview, action: .click, project: project)
    }

    func logFeedbackClose(project: WikimediaProject) {
        logEvent(activeInterface: .feedback, action: .closeFeedback, project: project)
    }

    func logFeedbackSubmit(project: WikimediaProject, selectedItem: Int, comment: String?) {

        var actionData = [
            "feedback_select": String(selectedItem)
        ]

        if let comment {
            actionData["feedback_comment"] = comment
        }
        logEvent(activeInterface: .feedback, action: .submitFeedback, actionData: actionData, project: project)
    }
}
