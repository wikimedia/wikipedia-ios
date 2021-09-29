
import Foundation

extension NotificationsCenterCellViewModel.IconNames {
    
    init(project: RemoteNotificationsProject, notification: RemoteNotification) {
        self.project = Self.determineProjectIconName(project: project)
    }
    
    private static func determineProjectIconName(project: RemoteNotificationsProject) -> String? {
        switch project {
        case .commons:
            return "notifications-project-commons"
        case .wikidata:
            return "notifications-project-wikidata"
        case .language:
            return nil
        }
    }
}
