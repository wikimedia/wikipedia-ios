import XCTest
import SwiftUI
@testable import WMFComponents

@MainActor
final class WMFBarButtonHostingViewTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// Lays the item out in the bar of a real navigation controller inside a window, as the app does.
    private func layOutInNavigationBar(leftBarButtonItem: UIBarButtonItem) {
        let rootViewController = UIViewController()
        rootViewController.navigationItem.leftBarButtonItem = leftBarButtonItem
        let navigationController = WMFComponentNavigationController(rootViewController: rootViewController, modalPresentationStyle: .pageSheet)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.2))
        navigationController.navigationBar.layoutIfNeeded()
        self.window = window
    }

    func testWrapperReportsContentSizeBeforeLayout() {
        let view = WMFBarButtonHostingView(rootView: WMFBetaBadge(label: "Beta"))

        XCTAssertGreaterThan(view.intrinsicContentSize.width, 20)
        XCTAssertGreaterThan(view.intrinsicContentSize.height, 10)
        XCTAssertEqual(view.frame.size, view.intrinsicContentSize)
    }

    func testNavigationBarGivesWrappedItemItsContentWidth() throws {
        let item = UIBarButtonItem.hostingBarButtonItem(rootView: WMFBetaBadge(label: "Beta"))
        let customView = try XCTUnwrap(item.customView)

        layOutInNavigationBar(leftBarButtonItem: item)

        XCTAssertNotNil(customView.superview)
        XCTAssertEqual(customView.frame.width, customView.intrinsicContentSize.width, accuracy: 1)
    }

    /// Documents why the wrapper exists. If this starts to fail, UIKit sizes a bare hosting view
    /// correctly and the wrapper can go.
    func testNavigationBarTruncatesBareHostingView() {
        let hostingController = UIHostingController(rootView: WMFBetaBadge(label: "Beta"))
        hostingController.sizingOptions = .intrinsicContentSize
        let fittingSize = hostingController.sizeThatFits(in: UIView.layoutFittingExpandedSize)
        hostingController.view.frame.size = fittingSize
        let item = UIBarButtonItem(customView: hostingController.view)

        layOutInNavigationBar(leftBarButtonItem: item)

        XCTAssertNotNil(hostingController.view.superview)
        XCTAssertLessThan(hostingController.view.frame.width, fittingSize.width - 1)
    }

    func testHostingItemPrefersTheVerticalBarOnIPhoneDuo() throws {
        guard #available(iOS 27.1, *) else { throw XCTSkip("axisBehavior needs iOS 27.1") }
        let item = UIBarButtonItem.hostingBarButtonItem(rootView: Text("Beta"))
        let optOut = UIBarButtonItem.hostingBarButtonItem(rootView: Text("Beta"), fitsVerticalBar: false)

        XCTAssertEqual(item.value(forKey: "axisBehavior") as? Int, 2, "2 is verticalPreferred")
        XCTAssertEqual(optOut.value(forKey: "axisBehavior") as? Int, 0, "0 is automatic")
    }
}
