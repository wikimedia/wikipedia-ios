import XCTest
import WMFComponents

@MainActor
final class WMFComponentNavigationControllerTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// Presents the navigation controller over a root screen in a window, as Settings is presented.
    private func present(_ navigationController: UINavigationController) {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        self.window = window
        let presented = expectation(description: "presented")
        presenter.present(navigationController, animated: false) { presented.fulfill() }
        wait(for: [presented], timeout: 5)
    }

    func testDismissalWithAPushedScreenOnTopCallsDidDismissOnce() {
        let navigationController = WMFComponentNavigationController(rootViewController: UIViewController(), modalPresentationStyle: .overFullScreen)
        let dismissed = expectation(description: "didDismiss")
        navigationController.didDismiss = { dismissed.fulfill() }
        present(navigationController)
        navigationController.pushViewController(UIViewController(), animated: false)

        navigationController.dismiss(animated: false)

        wait(for: [dismissed], timeout: 5)
    }

    func testPopDoesNotCallDidDismiss() {
        let navigationController = WMFComponentNavigationController(rootViewController: UIViewController(), modalPresentationStyle: .overFullScreen)
        var didDismissCount = 0
        navigationController.didDismiss = { didDismissCount += 1 }
        present(navigationController)
        navigationController.pushViewController(UIViewController(), animated: false)

        navigationController.popViewController(animated: false)
        let popped = expectation(description: "pop finished")
        DispatchQueue.main.async { popped.fulfill() }
        wait(for: [popped], timeout: 5)

        XCTAssertEqual(didDismissCount, 0)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }
}
