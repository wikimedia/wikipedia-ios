import Foundation

@objc
final class NotificationsCenterViewModel: NSObject {

	// MARK: - Properties

	let remoteNotificationsController: RemoteNotificationsController

	// MARK: - Lifecycle

	@objc
	init(remoteNotificationsController: RemoteNotificationsController) {
		self.remoteNotificationsController = remoteNotificationsController
	}

	// MARK: - Public

	// Data transformations

}
