import Foundation

final class NotificationsCenterCellViewModel {

	// MARK: - Properties

	let notification: RemoteNotification
	var displayState: NotificationsCenterCellDisplayState

	// MARK: - Lifecycle

	init(notification: RemoteNotification, displayState: NotificationsCenterCellDisplayState = .defaultUnread) {
		self.notification = notification
		self.displayState = displayState
	}

	// MARK: - Public

	var isRead: Bool {
		return notification.isRead
	}
	
}
