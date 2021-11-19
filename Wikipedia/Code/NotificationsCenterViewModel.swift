import Foundation
import CocoaLumberjackSwift
import Combine
import WMF

protocol NotificationCenterViewModelDelegate: AnyObject {

    /// This updates view controller subviews to reflect the new state it switches between various empty states and data states).
    func stateDidChange(_ newState: NotificationsCenterViewModel.State)
    func filtersToolbarViewModelDidChange(_ newViewModel: NotificationsCenterViewModel.FiltersToolbarViewModel)
    var numCellsSelected: Int { get }
}

enum NotificationsCenterSection {
  case main
}

@objc
final class NotificationsCenterViewModel: NSObject {
    
    struct FiltersToolbarViewModel {
        let areFiltersEnabled: Bool
        let countOfFilters: Int
        
        static func filtersToolbarViewModel(from remoteNotificationsController: RemoteNotificationsController) -> FiltersToolbarViewModel {
            
            return FiltersToolbarViewModel(areFiltersEnabled: remoteNotificationsController.areFiltersEnabled, countOfFilters: remoteNotificationsController.countOfFilters)
        }
    }
    
    private(set) var filtersToolbarViewModel: FiltersToolbarViewModel
    
    enum State {
        
        enum EmptyState {
            case initial
            case noData //pure empty state, not due to loading or filters or subscriptions. It's unlikely this state is ever achieved
            case loading
            case filters
            case subscriptions
        }
        
        enum DataState {
            
            enum Editing {
                case noneSelected(Int?)
                case oneOrMoreSelected(Int)
            }
            
            case nonEditing
            case editing(Editing)
        }
        
        case empty(EmptyState)
        case data([NotificationsCenterCellViewModel], DataState)
        
        var isEditing: Bool {
            switch self {
            case .data(_, let stateData):
                switch stateData {
                case .editing:
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
    }

    // MARK: - Properties

    let remoteNotificationsController: RemoteNotificationsController
    
    weak var delegate: NotificationCenterViewModelDelegate?

    let languageLinkController: MWKLanguageLinkController
    lazy private var modelController = NotificationsCenterModelController(languageLinkController: self.languageLinkController, delegate: self, remoteNotificationsController: remoteNotificationsController)
    
    private var isPagingEnabled = true
    
    private let stateSubject: PassthroughSubject<NotificationsCenterViewModel.State, Never>
    private var debouncedStateSubscription: AnyCancellable?
    
    private(set) var state: NotificationsCenterViewModel.State {
        didSet {
            switch state {
            case .empty(let emptyState):
                switch emptyState {
                case .loading: //sending to debouncer. Otherwise flash on screen when loading from db
                    stateSubject.send(state)
                    return
                default:
                    debouncedStateSubscription?.cancel()
                }
            case .data:
                debouncedStateSubscription?.cancel()
            }
            
            delegate?.stateDidChange(state)
            
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
        self.state = .empty(.initial)
        self.stateSubject = PassthroughSubject<NotificationsCenterViewModel.State, Never>()
        filtersToolbarViewModel = FiltersToolbarViewModel.filtersToolbarViewModel(from: remoteNotificationsController)

        super.init()
        
        self.debouncedStateSubscription = stateSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                
                self?.delegate?.stateDidChange($0)
                
            })
	}

    // MARK: - Public
    
    @objc func contextObjectsDidChange(_ notification: NSNotification) {
        
        //TODO: Handle other key types? (Deleted, Updated, Invalidated)
        let refreshedNotifications = notification.userInfo?[NSRefreshedObjectsKey] as? Set<RemoteNotification> ?? []
        let newNotifications = notification.userInfo?[NSInsertedObjectsKey] as? Set<RemoteNotification> ?? []
        
        guard (refreshedNotifications.count > 0 || newNotifications.count > 0) else {
            return
        }
        
        modelController.addNewCellViewModelsWith(notifications: Array(newNotifications), isEditing: state.isEditing)
        modelController.evaluateUpdatedNotifications(updatedNotifications: Array(refreshedNotifications), isEditing: state.isEditing)
    }

    // MARK: - Public
    
    func markAsReadOrUnread(viewModels: [NotificationsCenterCellViewModel], shouldMarkRead: Bool) {
        let identifierGroups = viewModels.map { $0.notification.identifierGroup }
        remoteNotificationsController.markAsReadOrUnread(identifierGroups: Set(identifierGroups), shouldMarkRead: shouldMarkRead, languageLinkController: languageLinkController)
    }
    
    func markAllAsRead() {
        remoteNotificationsController.markAllAsRead(languageLinkController: languageLinkController)
    }
    
    func refreshNotifications() {
        remoteNotificationsController.refreshNotifications { _ in
            //TODO: Set any refreshing loading states here
        }
    }
    
    func resetAndRefreshData() {
        modelController.reset(callbackForReload: true)
        fetchFirstPage()
        isPagingEnabled = true
    }
    
    func fetchFirstPage() {
        
        state = .empty(.loading)
        
        kickoffImportIfNeeded { [weak self] in
            
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                let notifications = self.remoteNotificationsController.fetchNotifications()
                if notifications.isEmpty {
                    if self.remoteNotificationsController.areFiltersEnabled {
                        self.state = .empty(.filters)
                    } else {
                        self.state = .empty(.noData)
                    }
                }
                self.modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: self.state.isEditing)
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
        
        modelController.addNewCellViewModelsWith(notifications: notifications, isEditing: state.isEditing)
    }
    
    func updateCellSelectionState(cellViewModel: NotificationsCenterCellViewModel, isSelected: Bool, callbackForReload: Bool = false) {
        modelController.updateCellDisplayStates(cellViewModels: [cellViewModel], isEditing: self.state.isEditing, isSelected: isSelected, callbackForReload: callbackForReload)
    }
    
    func updateStateFromEditingModeChange(isEditing: Bool) {
        modelController.updateCellDisplayStates(cellViewModels: modelController.sortedCellViewModels, isEditing: isEditing)
        guard let newState = newStateFromEditingModeChange(isEditing: isEditing) else {
            return
        }
        
        self.state = newState
    }
    
    func filtersToolbarViewModelNeedsReload() {
        self.filtersToolbarViewModel = FiltersToolbarViewModel.filtersToolbarViewModel(from: remoteNotificationsController)
        delegate?.filtersToolbarViewModelDidChange(self.filtersToolbarViewModel)
    }
}

private extension NotificationsCenterViewModel {
    func kickoffImportIfNeeded(completion: @escaping () -> Void) {
        remoteNotificationsController.importNotificationsIfNeeded() { [weak self] error in
            
            guard let self = self else {
                return
            }
            
            if let error = error,
               error == RemoteNotificationsOperationsError.dataUnavailable {
                //TODO: trigger error state of some sort
                completion()
                return
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.contextObjectsDidChange(_:)), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: self.remoteNotificationsController.viewContext)

            completion()
        }
    }
    
    var numberOfUnreadNotifications: Int? {
        return self.remoteNotificationsController.numberOfUnreadNotifications
    }
    
    func newStateFromEditingModeChange(isEditing: Bool) -> NotificationsCenterViewModel.State? {

        switch state {
        case .empty:
            assertionFailure("It should not be possible to change the editing state while in empty state mode. Edit button should be disabled.")
            return nil
        case .data(_, let dataState):
            switch dataState {
            case .editing:
                guard !isEditing else {
                    assertionFailure("Attempting to change into editing mode while already in editing mode. This seems odd.")
                    return nil
                }
                
                return .data(modelController.sortedCellViewModels, .nonEditing)
            case .nonEditing:
                guard isEditing else {
                    assertionFailure("Attempting to change into non-editing mode while already in non-editing mode. This seems odd.")
                    return nil
                }
                
                return .data(modelController.sortedCellViewModels, .editing(.noneSelected(numberOfUnreadNotifications)))
            }
        }
    }
    
    func newStateFromUnderlyingDataChange() -> NotificationsCenterViewModel.State {
        
        guard !modelController.sortedCellViewModels.isEmpty else {
            
            if self.remoteNotificationsController.areFiltersEnabled {
                return .empty(.filters)
            } else {
                return .empty(.noData)
            }
        }
        
        switch state {
        case .data(_, let dataState):
            //TODO: basic reassignment for the most part. Just need to account for number of selected cells
            switch dataState {
            case .nonEditing:
                return .data(modelController.sortedCellViewModels, .nonEditing)
            case .editing:
                let numberCellsSelected = delegate?.numCellsSelected ?? 0
                if numberCellsSelected == 0 {
                    return .data(modelController.sortedCellViewModels, .editing(.noneSelected(numberOfUnreadNotifications)))
                } else {
                    return .data(modelController.sortedCellViewModels, .editing(.oneOrMoreSelected(numberCellsSelected)))
                }
            }
        case .empty:
            return .data(modelController.sortedCellViewModels, .nonEditing)
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
        self.state = newStateFromUnderlyingDataChange()
    }
}
