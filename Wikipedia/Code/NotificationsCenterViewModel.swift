import Foundation
import CocoaLumberjackSwift
import Combine
import WMF
import UIKit

protocol NotificationCenterViewModelDelegate: AnyObject {

    /// This causes snapshot to update entirely, inserting new cells as needed
    /// It also asks the cells to reconfigure (for now, we might make this a distinct ask)
    func cellViewModelsDidChange(cellViewModels: [NotificationsCenterCellViewModel])
    
    //note: might want to separate this from toolbarDisplayState (mark/mark all vs filter/title/inbox) and toolbarContent (filter/title/inbox states and content)
    func toolbarDidUpdate()
}

enum NotificationsCenterSection {
  case main
}

@objc
final class NotificationsCenterViewModel: NSObject {

    // MARK: - Properties

    let remoteNotificationsController: RemoteNotificationsController
    
    weak var delegate: NotificationCenterViewModelDelegate?

    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, delegate: self, remoteNotificationsController: remoteNotificationsController)

    let languageLinkController: MWKLanguageLinkController

    private var isLoading: Bool = false {
        didSet {
            delegate?.toolbarDidUpdate()
        }
    }

    private var isPagingEnabled = true

    var isEditing = false {
        didSet {
            if oldValue != isEditing {
                updateStateFromEditingModeChange(isEditing: isEditing)
            }
        }
    }
    
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

    // MARK: - Public
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        //TODO: Handle other key types? (Deleted, Updated, Invalidated)
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        modelController.evaluateUpdatedNotifications(updatedNotifications: Array(refreshedNotifications), isEditing: isEditing)
        modelController.addNewCellViewModelsWith(notifications: Array(newNotifications), isEditing: isEditing)
    }

    // MARK: - Public
    
    func refreshNotifications(force: Bool) {
        isLoading = true
        remoteNotificationsController.refreshNotifications(force: force) { _ in
            //TODO: Set any refreshing loading states here
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
    
    func resetAndRefreshData() {
        modelController.reset()
        fetchFirstPage()
        isPagingEnabled = true
    }
    
    func fetchFirstPage() {
        
        isLoading = true
        
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                self.modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: self.isEditing)
            }
        }
    }
    
    func fetchNextPage() {
        
        guard isPagingEnabled == true else {
            DDLogDebug("Request to fetch next page while paging is disabled. Ignoring.")
            return
        }
        
        let notifications = self.remoteNotificationsController.fetchNotifications(fetchOffset: modelController.fetchOffset)
        
        guard notifications.count > 0 else {
            isPagingEnabled = false
            return
        }
        
        modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: isEditing)
    }
    
    func updateCellDisplayStates(cellViewModels: [NotificationsCenterCellViewModel], isSelected: Bool? = nil) {
        modelController.updateCellDisplayStates(cellViewModels: cellViewModels, isEditing: self.isEditing, isSelected: isSelected)
    }
    
    func updateStateFromEditingModeChange(isEditing: Bool) {
        self.isEditing = isEditing
        updateCellDisplayStates(cellViewModels: modelController.sortedCellViewModels)
        delegate?.toolbarDidUpdate()
    }
    
    var numberOfUnreadNotifications: Int? {
        return self.remoteNotificationsController.numberOfUnreadNotifications
    }
}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
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

                completion()
            }
        }
    }
}

extension NotificationsCenterViewModel: NotificationsCenterModelControllerDelegate {
    //Happens when:
    //Core Data listener indicates new notifications managed objects have been updated or inserted into the database. Would get called during a data refresh.
    //The first page of notifications have been fetched from the database, transformed into cell view models and added to the model controller
    //The next page of notifications have been fetched from the database, transformed into cell view models and added to the model controller.
    //Note all of these have the capability of switching the state from an empty state to a data state (and vice versa), of inserting additional cell view models thus requiring a diffable snapshot update, as well as changing the underlying cell view model states, thus requiring a cell reload.
    func dataDidChange() {
        delegate?.cellViewModelsDidChange(cellViewModels: modelController.sortedCellViewModels)
    }
}

// MARK: - Toolbar

extension NotificationsCenterViewModel {

    // MARK: - Private

    @objc fileprivate func remoteNotificationsControllerDidUpdateFilterState() {
        delegate?.toolbarDidUpdate()
    }

    fileprivate func toolbarImageForTypeFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle"
        return UIImage(systemName: symbolName)
    }

    fileprivate func toolbarImageForProjectFilter(engaged: Bool) -> UIImage? {
        let symbolName = engaged ? "tray.fill" : "tray.2"
        return UIImage(systemName: symbolName)
    }

    // MARK: - Public

    var typeFilterButtonImage: UIImage? {
        return toolbarImageForTypeFilter(engaged: remoteNotificationsController.filterState.types.count > 0 || remoteNotificationsController.filterState.readStatus != .all)
    }

    var projectFilterButtonImage: UIImage? {
        return toolbarImageForProjectFilter(engaged: remoteNotificationsController.filterState.projects.count > 0)
    }

    var statusBarText: String {
        if isLoading {
            return "Checking for notifications..."
        }

        // Logic for status bar text based on type, project, and read filters here

        return "All Notifications"
    }
    
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
