import CocoaLumberjackSwift

@objc public final class RemoteNotificationsController: NSObject {
    private let operationsController: RemoteNotificationsOperationsController

    public static let didUpdateFilterStateNotification = NSNotification.Name(rawValue: "RemoteNotificationsControllerDidUpdateFilterState")
    
    public var viewContext: NSManagedObjectContext? {
        return operationsController.viewContext
    }
    
    public let configuration: Configuration
    
    @objc public required init(session: Session, configuration: Configuration, preferredLanguageCodesProvider: WMFPreferredLanguageInfoProvider) {
        operationsController = RemoteNotificationsOperationsController(session: session, configuration: configuration, preferredLanguageCodesProvider: preferredLanguageCodesProvider)
        self.configuration = configuration
        super.init()
    }
    
    @objc func deleteLegacyDatabaseFiles() {
        do {
            try operationsController.deleteLegacyDatabaseFiles()
        } catch (let error) {
            DDLogError("Failure deleting legacy RemoteNotifications database files: \(error)")
        }
    }
        
    public func importNotificationsIfNeeded(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        operationsController.importNotificationsIfNeeded(completion)
    }
    
    public func refreshNotifications(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        operationsController.refreshNotifications(completion)
    }

    public func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool) {
        operationsController.markAsReadOrUnread(identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead)
    }
    
    public func markAllAsRead() {
        operationsController.markAllAsRead()
    }

    public func fetchNotifications(fetchLimit: Int = 50, fetchOffset: Int = 0) -> [RemoteNotification] {
        assert(Thread.isMainThread)
        
        guard let viewContext = self.viewContext else {
            DDLogError("Failure fetching notifications from persistence: missing viewContext")
            return []
        }
        
        let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.fetchOffset = fetchOffset
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            DDLogError("Failure fetching notifications from persistence: \(error)")
            return []
        }
    }

    // TODO: - A count of the total locally available to the user projects/inboxes. Where should this go and how should it be populated?
    public lazy var totalLocalProjectsCount: Int = 5

    public lazy var filterState: RemoteNotificationsFilterState = {
        return RemoteNotificationsFilterState(readStatus: .all, types: [], projects: [])
    }() {
        didSet {
            NotificationCenter.default.post(name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
        }
    }

}

public struct RemoteNotificationsFilterState {

    public enum ReadStatus: Int, CaseIterable {
        case all
        case read
        case unread

        var localizedDescription: String {
            switch self {
            case .all:
                return CommonStrings.notificationsCenterAllNotificationsStatus
            case .read:
                return CommonStrings.notificationsCenterReadNotificationsStatus
            case .unread:
                return CommonStrings.notificationsCenterUnreadNotificationsStatus
            }
        }
    }

    public let readStatus: ReadStatus
    public let types: [RemoteNotificationType]
    public let projects: [RemoteNotificationsProject]

    public init(readStatus: ReadStatus, types: [RemoteNotificationType], projects: [RemoteNotificationsProject]) {
        self.readStatus = readStatus
        self.types = types
        self.projects = projects
    }

    private var isReadStatusOrTypeFiltered: Bool {
        return (readStatus != .all || !types.isEmpty)
    }

    public var stateDescription: String {
        let filteredBy = WMFLocalizedString("notifications-center-status-filtered-by", value: "Filtered by", comment: "Status header text in Notifications Center displayed when filtering notifications.")

        let allNotifications = WMFLocalizedString("notifications-center-status-all-notifications", value: "All notifications", comment: "Status header text in Notifications Center displayed when viewing unfiltered list of notifications.")

        let headerText = isReadStatusOrTypeFiltered ? filteredBy : allNotifications
        return headerText
    }

    public static var detailDescriptionHighlightDelineator = "**"

    public func detailDescription(totalProjectCount: Int) -> String? {
        // Generic templates

        let doubleConcatenationTemplate = WMFLocalizedString("notifications-center-status-double-concatenation", value: "%1$@ in %2$@", comment: "Notifications Center status description. %1$@ is replaced with the currently applied filters and %2$@ is replaced with the count of projects/inboxes.")

        let tripleConcatenationTemplate = WMFLocalizedString("notifications-center-status-triple-concatenation", value: "%1$@ and %2$@ in %3$@", comment: "Notifications Center status description. %1$@ is replaced with the currently applied read status filter, %2$@ is replaced with the count of notification type filters, and %3$@ is replaced with the count of projects/inboxes.")

        // Specific plurals

        let inProjects = WMFLocalizedString("notifications-center-status-in-projects", value: "{{PLURAL:%1$d|1=In 1 project|In %1$d projects}}", comment: "Notifications Center status description when filtering by projects/inboxes. %1$d is replaced by the count of local projects.")

        let projectsPlain = WMFLocalizedString("notifications-center-status-in-projects-plain", value: "{{PLURAL:%1$d|1=1 project|%1$d projects}}", comment: "Notifications Center status description when filtering by projects/inboxes, without preposition. %1$d is replaced by the count of local projects.")

        let typesPlain = WMFLocalizedString("notifications-center-status-in-types", value: "{{PLURAL:%1$d|1=1 type|%1$d types}}", comment: "Notifications Center status description when filtering by types. %1$d is replaced by the count of filtered types.")

        var descriptionString: String?

        switch (readStatus, types.count, projects.count) {
        case (.all, 0, 0):
            // No filtering
            descriptionString = String.localizedStringWithFormat(inProjects, totalProjectCount)
        case (.all, 0..., 0):
            // Only filtering by type
            descriptionString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
        case (.all, 0, 0...):
            // Only filtering by project/inbox
            descriptionString = String.localizedStringWithFormat(inProjects, projects.count).highlightDelineated
        case (.read, 0, 0), (.unread, 0, 0):
            // Only filtering by read status
            let totalProjectString = String.localizedStringWithFormat(projectsPlain, totalProjectCount)
            descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, totalProjectString)
        case (.read, 0..., 0), (.unread, 0..., 0):
            // Filtering by read status and type
            let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
            let totalProjectString = String.localizedStringWithFormat(projectsPlain, totalProjectCount)
            descriptionString = String.localizedStringWithFormat(tripleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, typesString, totalProjectString)
        case (.read, 0, 0...), (.unread, 0, 0...):
            // Filtering by read status and project/inbox
            let projectString = String.localizedStringWithFormat(projectsPlain, projects.count).highlightDelineated
            descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, readStatus.localizedDescription.highlightDelineated, projectString)
        case (let readStatus, 0..., 0...):
            // Filtering by type, project/inbox, and potentially read status
            switch readStatus {
            case .all:
                // Filtering by type and project/inbox
                let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, projects.count).highlightDelineated
                descriptionString = String.localizedStringWithFormat(doubleConcatenationTemplate, typesString, projectString)
            case .read, .unread:
                // Filtering by read status, type, and project/inbox
                let readString = readStatus.localizedDescription.highlightDelineated
                let typesString = String.localizedStringWithFormat(typesPlain, types.count).highlightDelineated
                let projectString = String.localizedStringWithFormat(projectsPlain, projects.count).highlightDelineated
                descriptionString = String.localizedStringWithFormat(tripleConcatenationTemplate, readString, typesString, projectString)
            }
        default:
            break
        }

        return descriptionString
    }
    
}

fileprivate extension String {

    /// Delineated section of string to be highlighted in attributed string
    var highlightDelineated: String {
        return RemoteNotificationsFilterState.detailDescriptionHighlightDelineator + self + RemoteNotificationsFilterState.detailDescriptionHighlightDelineator
    }

}
