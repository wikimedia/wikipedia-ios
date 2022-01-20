import Foundation
import CocoaLumberjackSwift
import WMF
import UIKit

enum NotificationCenterUpdateType {
    case emptyDisplay(Bool)
    case emptyContent
    case toolbarDisplay
    case toolbarContent
    case reconfigureCells([NotificationsCenterCellViewModel]) //reconfigures cells without instantiating new cells or updating the snapshot
    case updateSnapshot([NotificationsCenterCellViewModel]) //updates the snapshot for inserting / deleting cells
}

protocol NotificationCenterViewModelDelegate: AnyObject {
    func update(types: [NotificationCenterUpdateType])
}

enum NotificationsCenterSection {
  case main
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    let remoteNotificationsController: RemoteNotificationsController
    
    weak var delegate: NotificationCenterViewModelDelegate?

    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, remoteNotificationsController: remoteNotificationsController)

    let languageLinkController: MWKLanguageLinkController

    private var isLoading: Bool = false {
        didSet {
            delegate?.update(types: [.emptyContent, .toolbarContent])
        }
    }

    private var isPagingEnabled = true

    var isEditing = false
    
    var configuration: Configuration {
        return remoteNotificationsController.configuration
    }

    // MARK: - Lifecycle

    @objc
    init(remoteNotificationsController: RemoteNotificationsController, languageLinkController: MWKLanguageLinkController) {
        self.remoteNotificationsController = remoteNotificationsController
        self.languageLinkController = languageLinkController
        
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(remoteNotificationsControllerDidUpdateFilterState), name: RemoteNotificationsController.didUpdateFilterStateNotification, object: nil)
	}

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        //TODO: Handle other key types? (Deleted, Updated, Invalidated)
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        var updateTypes: [NotificationCenterUpdateType] = []
        
        let refreshUpdateTypes = modelController.evaluateUpdatedNotifications(updatedNotifications: Array(refreshedNotifications), isEditing: isEditing)
        updateTypes.append(contentsOf: refreshUpdateTypes)
        
        if let insertUpdateType = modelController.addNewCellViewModelsWith(notifications: Array(newNotifications), isEditing: isEditing) {
            updateTypes.append(insertUpdateType)
        }
        
        updateTypes.append(.emptyDisplay(modelController.countOfTrackingModels == 0))
        updateTypes.append(.emptyContent)
        
        if updateTypes.count > 0 {
            delegate?.update(types: updateTypes)
        }
    }

    // MARK: - Public
    
    func setup() {
        //TODO: Revisit and enable importing empty states in a delayed manner to avoid flashing.
        delegate?.update(types: [.emptyDisplay(true), .toolbarDisplay])
    }
    
    func refreshNotifications(force: Bool) {
        isLoading = true
        remoteNotificationsController.refreshNotifications(force: force) { error in
            //TODO: Set any refreshing loading states here
            if let error = error as? RemoteNotificationsOperationsError,
               error == .alreadyImportingOrRefreshing {
                //don't turn off loading state
                return
            }
            
            self.isLoading = false
        }
    }
    
    func markAsReadOrUnread(viewModels: [NotificationsCenterCellViewModel], shouldMarkRead: Bool) {
        let identifierGroups = viewModels.map { $0.notification.identifierGroup }
        remoteNotificationsController.markAsReadOrUnread(identifierGroups: Set(identifierGroups), shouldMarkRead: shouldMarkRead, languageLinkController: languageLinkController)
    }
    
    func markAllAsRead() {
        remoteNotificationsController.markAllAsRead(languageLinkController: languageLinkController)
    }
    
    func fetchFirstPage() {
        
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                var updateTypes: [NotificationCenterUpdateType] = []
                if let updateType = self.modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: self.isEditing) {
                    updateTypes.append(updateType)
                }
                
                updateTypes.append(contentsOf: [.toolbarContent, .emptyContent, .emptyDisplay(self.modelController.countOfTrackingModels == 0)])
                
                self.delegate?.update(types: updateTypes)
            }
        }
    }
    
    func fetchNextPage() {
        
        guard isPagingEnabled == true else {
            DDLogDebug("Request to fetch next page while paging is disabled. Ignoring.")
            return
        }
        
        let notifications = self.remoteNotificationsController.fetchNotifications(fetchOffset: modelController.countOfTrackingModels)
        
        guard notifications.count > 0 else {
            isPagingEnabled = false
            return
        }
        
        if let updateType = modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: isEditing) {
            delegate?.update(types: [updateType])
        }
    }
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel]? = nil, isSelected: Bool? = nil) {
        if let updateType = modelController.updateCellDisplayStates(cellViewModels: cellViewModels, isEditing: isEditing, isSelected: isSelected) {
            delegate?.update(types: [updateType])
        }
    }
    
    func updateEditingModeState(isEditing: Bool) {
        self.isEditing = isEditing
        
        var updateTypes: [NotificationCenterUpdateType] = []
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

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
        
        isLoading = true
        
        remoteNotificationsController.importNotificationsIfNeeded() { [weak self] error in
            
            guard let self = self else {
                return
            }
            
            if let error = error as? RemoteNotificationsOperationsError,
               error == RemoteNotificationsOperationsError.dataUnavailable {
                //TODO: trigger error state of some sort
                completion()
                return
            }
            
            self.remoteNotificationsController.setupInitialFilters(languageLinkController: self.languageLinkController) {
                NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.remoteNotificationsController.viewContext)

                self.isLoading = false
                completion()
            }
        }
    }
}

// MARK: - Toolbar

extension NotificationsCenterViewModel {

    // MARK: - Private

    @objc fileprivate func remoteNotificationsControllerDidUpdateFilterState() {
        //Not doing anything here yet
        //Because filter screen disapperances call self.resetAndRefreshData from the view controller, which fetches the first page again and relays state changes back to the view controller, there's no need to react to this notification.
    }

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

        let totalProjectCount = remoteNotificationsController.totalLocalProjectsCount
        let filterState = remoteNotificationsController.filterState
        let headerText = filterState.stateDescription
        let subheaderText = filterState.detailDescription(totalProjectCount: totalProjectCount)

        if let subheaderText = subheaderText {
            return headerText + "\n" + subheaderText
        }

        return headerText
    }

    // MARK: - Public

    var typeFilterButtonImage: UIImage? {
        return toolbarImageForTypeFilter(engaged: remoteNotificationsController.filterState.types.count > 0 || remoteNotificationsController.filterState.readStatus != .all)
    }

    var projectFilterButtonImage: UIImage? {
        return toolbarImageForProjectFilter(engaged: remoteNotificationsController.filterState.projects.count > 0)
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
    
    var numberOfUnreadNotifications: Int? {
        return self.remoteNotificationsController.numberOfUnreadNotifications
    }
}

//MARK: - Empty State

extension NotificationsCenterViewModel {
    
    //MARK: Public
    
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
        guard remoteNotificationsController.countOfTypeFilters > 0 else {
            return nil
        }
            
        let filtersLinkFormat = WMFLocalizedString("notifications-center-empty-state-num-filters", value:"{{PLURAL:%1$d|%1$d filter|%1$d filters}}", comment:"Portion of empty state subtitle showing number of filters the user has set in notifications center - %1$d is replaced with the number filters.")
        let filtersSubtitleFormat = WMFLocalizedString("notifications-center-empty-state-filters-subtitle", value:"Modify %1$@ to see more messages", comment:"Format of empty state subtitle when the user has filters on - %1$@ is replaced with a string representing the number of filters the user has set.")
        let filtersLink = String.localizedStringWithFormat(filtersLinkFormat, remoteNotificationsController.countOfTypeFilters)
        let filtersSubtitle = String.localizedStringWithFormat(filtersSubtitleFormat, filtersLink)

        let rangeOfFiltersLink = (filtersSubtitle as NSString).range(of: filtersLink)

        let font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
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
