import CocoaLumberjackSwift
import WMF
import WMFComponents

enum NotificationsCenterUpdateType {
    case emptyDisplay(Bool)
    case emptyContent
    case toolbarDisplay
    case toolbarContent
    case reconfigureCells([NotificationsCenterCellViewModel]) // reconfigures cells without instantiating new cells or updating the snapshot
    case updateSnapshot([NotificationsCenterCellViewModel]) // updates the snapshot for inserting / deleting cells
    case endRefreshing
}

protocol NotificationsCenterViewModelDelegate: AnyObject {
    func update(types: [NotificationsCenterUpdateType])
}

enum NotificationsCenterSection {
  case main
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    let notificationsController: WMFNotificationsController
    let remoteNotificationsController: RemoteNotificationsController
    
    weak var delegate: NotificationsCenterViewModelDelegate?

    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, remoteNotificationsController: remoteNotificationsController, configuration: configuration)

    let languageLinkController: MWKLanguageLinkController

    private var isLoading: Bool = false {
        didSet {
            
            // This setter may be called often due to quickly firing NSNotifications.
            // Don't allow a view update unless something has actually changed.
            if oldValue != isLoading {
                var updateTypes: [NotificationsCenterUpdateType] = [.emptyContent, .toolbarContent]
                if !isLoading {
                    updateTypes.insert(.endRefreshing, at: 0)
                }
                delegate?.update(types: updateTypes)
            }
        }
    }

    private var isPagingEnabled = true

    var isEditing = false
    
    var configuration: Configuration {
        return remoteNotificationsController.configuration
    }

    // MARK: - Lifecycle

    @objc
    init(notificationsController: WMFNotificationsController, remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.notificationsController = notificationsController
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController
        
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(remoteNotificationsControllerDidUpdateFilterState), name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingDidStart), name: Notification.Name.NotificationsCenterLoadingDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingDidEnd), name: Notification.Name.NotificationsCenterLoadingDidEnd, object: nil)
	}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: NSNotifications
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let insertedNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        let insertedNotificationsToDisplay = notificationsToDisplayFromManagedObjectContextInsert(insertedNotifications: insertedNotifications)
        
        guard refreshedNotifications.count > 0 || insertedNotificationsToDisplay.count > 0 else {
            return
        }
        
        var updateTypes: [NotificationsCenterUpdateType] = []
        
        let refreshUpdateTypes = modelController.evaluateUpdatedNotifications(updatedNotifications: Array(refreshedNotifications), isEditing: isEditing)
        updateTypes.append(contentsOf: refreshUpdateTypes)
        
        if let insertUpdateType = modelController.addNewCellViewModelsWith(notifications: Array(insertedNotificationsToDisplay), isEditing: isEditing) {
            updateTypes.append(insertUpdateType)
        }
        
        updateTypes.append(.emptyDisplay(modelController.countOfTrackingModels == 0))
        updateTypes.append(.emptyContent)
        
        if updateTypes.count > 0 {
            delegate?.update(types: updateTypes)
        }
    }
    
    private func notificationsToDisplayFromManagedObjectContextInsert(insertedNotifications: Set<RemoteNotification>) -> Set<RemoteNotification> {
        
        // run new notifications through saved filter so we're not inserting objects that shouldn't display
        var notificationsToDisplay = insertedNotifications
        if let predicate = remoteNotificationsController.filterPredicate {
            notificationsToDisplay = (insertedNotifications as NSSet).filtered(using: predicate) as? Set<RemoteNotification> ?? insertedNotifications
        }
        
        // do not insert any notifications older than the oldest displayed notification.
        // subsequent page fetches should eventually pull these
        if let oldestDisplayedDate = modelController.oldestDisplayedNotificationDate {
            notificationsToDisplay = notificationsToDisplay.filter({ notification in
                if let notificationDate = notification.date {
                    return oldestDisplayedDate < notificationDate
                }
                
                return false
            })
        }
        
        
        return notificationsToDisplay
    }
    
    @objc private func remoteNotificationsControllerDidUpdateFilterState() {
        // Not doing anything here yet
        // Because filter screen disapperances call self.resetAndRefreshData from the view controller, which fetches the first page again and relays state changes back to the view controller, there's no need to react to this notification.
    }
    
    @objc private func loadingDidStart() {
        DispatchQueue.main.async {
            self.isLoading = true
        }
    }
    
    @objc private func loadingDidEnd() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    // MARK: - Public
    
    func setup() {
        isLoading = remoteNotificationsController.isLoadingNotifications
        delegate?.update(types: [.emptyDisplay(true), .toolbarDisplay])
    }
    
    func refreshNotifications(force: Bool) {
        remoteNotificationsController.loadNotifications(force: force) { result in
            switch result {
            case .failure(let error):
                if case RemoteNotificationsControllerError.attemptingToRefreshBeforeDeadline = error {
                    break
                }
                DDLogError("Error refreshing notifications: \(error)")
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            default:
                break
            }
        }
    }
    
    func markAsReadOrUnread(viewModels: [NotificationsCenterCellViewModel], shouldMarkRead: Bool, shouldDisplayErrorIfNeeded: Bool = true) {
        
        let identifierGroups = viewModels.map { $0.notification.identifierGroup }
        remoteNotificationsController.markAsReadOrUnread(identifierGroups: Set(identifierGroups), shouldMarkRead: shouldMarkRead) { result in
            switch result {
            case .failure(let error):
                DDLogError("Error marking notifications as read or unread: \(error)")
                if shouldDisplayErrorIfNeeded {
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                }
            default:
                break
            }
        }
    }
    
    func markAllAsRead() {
        remoteNotificationsController.markAllAsRead { result in
            switch result {
            case .failure(let error):
                DDLogError("Error marking all notifications as read or unread: \(error)")
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            default:
                break
            }
        }
    }
    
    func markAllAsSeen() {
        
        // do not mark as seen if view is showing an empty state due to filters or loading
        if modelController.countOfTrackingModels == 0 && (remoteNotificationsController.areFiltersEnabled || remoteNotificationsController.isLoadingNotifications) {
            return
        }
        
        remoteNotificationsController.markAllAsSeen { result in
            switch result {
            case let .failure(error):
                DDLogError("Error marking all notifications as seen: \(error)")
            default:
                break
            }
        }
    }
    
    func fetchFirstPage() {
        
        remoteNotificationsController.fetchNotifications { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let notifications):
                var updateTypes: [NotificationsCenterUpdateType] = []
                if let updateType = self.modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: self.isEditing) {
                    updateTypes.append(updateType)
                }
                
                updateTypes.append(contentsOf: [.toolbarContent, .emptyContent, .emptyDisplay(self.modelController.countOfTrackingModels == 0)])
                
                self.delegate?.update(types: updateTypes)
                
                // This allows the collection view to react to new inserted or updated objects from a refresh or mark as read/unread call.
                // But we don't care to listen for it until after the first page is already fetched from the database and is displaying on screen.
                self.remoteNotificationsController.addObserverForViewContextChanges(observer: self, selector: #selector(self.contextObjectsDidChange(_:)))
            case .failure(let error):
                DDLogError("Error fetching first page of notifications: \(error)")
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            }
        }
    }
    
    func fetchNextPage() {
        
        guard isPagingEnabled == true else {
            DDLogDebug("Request to fetch next page while paging is disabled. Ignoring.")
            return
        }
        
        remoteNotificationsController.fetchNotifications(fetchOffset: modelController.countOfTrackingModels) { [weak self] result in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let notifications):

                guard notifications.count > 0 else {
                    self.isPagingEnabled = false
                    return
                }
                
                if let updateType = self.modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: self.isEditing) {
                    self.delegate?.update(types: [updateType])
                }
                
            case .failure(let error):
                DDLogError("Error fetching next page of notifications: \(error)")
            }
        }
        
        
    }
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel]? = nil, isSelected: Bool? = nil) {
        if let updateType = modelController.updateCellDisplayStates(cellViewModels: cellViewModels, isEditing: isEditing, isSelected: isSelected) {
            delegate?.update(types: [updateType])
        }
    }
    
    func updateEditingModeState(isEditing: Bool) {
        self.isEditing = isEditing
        
        var updateTypes: [NotificationsCenterUpdateType] = []
        if let updateType = modelController.updateCellDisplayStates(isEditing: self.isEditing) {
            updateTypes.append(updateType)
        }
        
        updateTypes.append(.toolbarDisplay)
        delegate?.update(types: updateTypes)
    }
    
    func resetAndRefreshData() {
        modelController.reset()
        fetchFirstPage()
        isPagingEnabled = true
    }
}

// MARK: - Toolbar

extension NotificationsCenterViewModel {

    // MARK: - Private

    fileprivate func toolbarImageForTypeFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle"
        return UIImage(systemName: symbolName)
    }

    fileprivate func toolbarImageForProjectFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "tray.fill" : "tray.2"
        return UIImage(systemName: symbolName)
    }

    private var rawStatusBarText: String? {
        if isLoading {
            let checkingForNotifications = WMFLocalizedString("notifications-center-checking-for-notifications", value: "Checking for notifications...", comment: "Status text displayed in Notifications Center when checking for notifications.")
            return checkingForNotifications
        }

        let totalProjectCount = remoteNotificationsController.allInboxProjects.count
        let showingProjectCount = remoteNotificationsController.countOfShowingInboxProjects
        let filterState = remoteNotificationsController.filterState
        let headerText = filterState.stateDescription
        let subheaderText = filterState.detailDescription(totalProjectCount: totalProjectCount, showingProjectCount: showingProjectCount)

        if let subheaderText = subheaderText {
            return headerText + "\n" + subheaderText
        }

        return headerText
    }

    // MARK: - Public

    var typeFilterButtonImage: UIImage? {
        return toolbarImageForTypeFilter(engaged: areFiltersApplied)
    }
    
    var filterButtonAccessibilityLabel: String {
        return areFiltersApplied ?
        WMFLocalizedString("notifications-center-applied-filters-accessibility-label", value: "Notifications Filter - has filters applied", comment: "Accessibility label for Notifications Center's filters button. This button is in a selected state indicating that filters are applied.")
         : WMFLocalizedString("notifications-center-filters-accessibility-label", value: "Notifications Filter", comment: "Accessibility label for Notifications Center's filters button. This button is in an unselected state indicating that filters are not applied.")
    }

    var projectFilterAccessibilityLabel: String {
        return remoteNotificationsController.filterState.offProjects.count > 0 ?
        WMFLocalizedString("notifications-center-applied-project-filters-accessibility-label", value: "Projects Filter - has filters applied", comment: "Accessibility label for Notifications Center's project filters button. This button is in a selected state indicating that project filters are applied.")
         : WMFLocalizedString("notifications-center-project-filters-accessibility-label", value: "Projects Filter", comment: "Accessibility label for Notifications Center's project filters button. This button is in an unselected state indicating that project filters are not applied.")
    }

    var projectFilterButtonImage: UIImage? {
        return toolbarImageForProjectFilter(engaged: remoteNotificationsController.filterState.offProjects.count > 0)
    }

    var areFiltersApplied: Bool {
        return remoteNotificationsController.filterState.offTypes.count > 0 || remoteNotificationsController.filterState.readStatus != .all
    }

    var filterAndInboxButtonsAreDisabled: Bool {
        modelController.countOfTrackingModels == 0 && isLoading && !remoteNotificationsController.isFullyImported
    }

    func statusBarText(textColor: UIColor, highlightColor: UIColor) -> NSAttributedString? {
        guard let rawStatusBarText = rawStatusBarText else {
            return nil
        }

        // Adapted from https://www.swiftbysundell.com/articles/styled-localized-strings-in-swift/

        let components = rawStatusBarText.components(separatedBy: RemoteNotificationsFilterState.detailDescriptionHighlightDelineator)
        let sequence = components.enumerated()
        let attributedString = NSMutableAttributedString()

        return sequence.reduce(into: attributedString) { string, pair in
            let isHighlighted = !pair.offset.isMultiple(of: 2)
            let color = isHighlighted ? highlightColor : textColor
            string.append(NSAttributedString(string: pair.element, attributes: [.foregroundColor: color]))
        }
    }
    
    var numberOfUnreadNotifications: Int {
        return (try? self.remoteNotificationsController.numberOfUnreadNotifications().intValue) ?? 0
    }
}

// MARK: - Empty State

extension NotificationsCenterViewModel {
    
    // MARK: Public
    
    var emptyStateHeaderText: String {
        return NotificationsCenterView.EmptyOverlayStrings.noUnreadMessages
    }
    
    var emptyStateSubheaderText: String {
        if isLoading {
            return NotificationsCenterView.EmptyOverlayStrings.checkingForNotifications
        } else {
            return ""
        }
    }
    
    func emptyStateSubheaderAttributedString(theme: Theme, traitCollection: UITraitCollection) -> NSAttributedString? {
        guard remoteNotificationsController.allInboxProjects.count != remoteNotificationsController.filterState.offProjects.count else {
            let noProjectsSelected = WMFLocalizedString("notifications-center-empty-state-no-projects-selected", value:"Add projects to see more messages", comment:"Empty state subtitle indicating the user has unselected all projects.")
            return NSAttributedString(string: noProjectsSelected)
        }

        let filterTypesCount = remoteNotificationsController.filterState.offTypes.count
        guard filterTypesCount > 0 else {
            return nil
        }
            
        let filtersLinkFormat = WMFLocalizedString("notifications-center-empty-state-num-filters", value:"{{PLURAL:%1$d|%1$d filter|%1$d filters}}", comment:"Portion of empty state subtitle showing number of filters the user has set in notifications center - %1$d is replaced with the number filters.")
        let filtersSubtitleFormat = WMFLocalizedString("notifications-center-empty-state-filters-subtitle", value:"Modify %1$@ to see more messages", comment:"Format of empty state subtitle when the user has filters on - %1$@ is replaced with a string representing the number of filters the user has set.")
        let filtersLink = String.localizedStringWithFormat(filtersLinkFormat, filterTypesCount)
        let filtersSubtitle = String.localizedStringWithFormat(filtersSubtitleFormat, filtersLink)

        let rangeOfFiltersLink = (filtersSubtitle as NSString).range(of: filtersLink)

        let font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: theme.colors.secondaryText
            ]
        let linkAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: theme.colors.link
            ]

        let attributedString = NSMutableAttributedString(string: filtersSubtitle)
        attributedString.setAttributes(attributes, range: NSRange(location: 0, length: filtersSubtitle.count) )
        if rangeOfFiltersLink.location != NSNotFound {
            attributedString.setAttributes(linkAttributes, range: rangeOfFiltersLink)
        }

        return attributedString.copy() as? NSAttributedString
    }

}
