import UIKit

/// Coordinator: Protocol for handling navigation. A coordinator owns a navigation flow, and handles the presentation of view controllers.
/// It can handle the dependencies of the View Controllers it manages.
/// Properties:
/// - navigationController: The navigation controller that the coordinator uses to manage view controllers.
/// Methods:
/// start():  Starts the coordinator's navigation flow. Should be called to trigger the presentation of the View Controllers.
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }

    func start()
}
