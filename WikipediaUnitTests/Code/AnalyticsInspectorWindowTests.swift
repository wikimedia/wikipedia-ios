import XCTest
import WMFComponents
@testable import Wikipedia

@MainActor
final class AnalyticsInspectorWindowTests: XCTestCase {

    private var window: AnalyticsInspectorWindow!
    private var pillViewController: WMFAnalyticsInspectorPillViewController!

    override func setUp() async throws {
        try await super.setUp()
        pillViewController = WMFAnalyticsInspectorPillViewController(viewModel: WMFAnalyticsInspectorViewModel())
        window = AnalyticsInspectorWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = pillViewController
        window.isHidden = false
        pillViewController.view.frame = window.bounds
        pillViewController.view.layoutIfNeeded()
    }

    override func tearDown() async throws {
        window.isHidden = true
        window = nil
        pillViewController = nil
        try await super.tearDown()
    }

    func testTouchesOutsideThePillPassThrough() {
        let point = CGPoint(x: 20, y: 700)

        XCTAssertNil(window.hitTest(point, with: nil))
    }

    func testTouchesOnThePillStayInTheWindow() {
        let pillFrame = pillViewController.pillView.convert(pillViewController.pillView.bounds, to: window)
        XCTAssertFalse(pillFrame.isEmpty, "The pill needs a size to take touches")

        let hit = window.hitTest(CGPoint(x: pillFrame.midX, y: pillFrame.midY), with: nil)

        XCTAssertNotNil(hit)
        XCTAssertTrue(hit?.isDescendant(of: pillViewController.pillView) ?? false)
    }

    func testThePillSitsUnderTheTopTrailingSafeArea() {
        let rootView = pillViewController.view!
        let safeArea = rootView.safeAreaLayoutGuide.layoutFrame
        let pillFrame = pillViewController.pillView.convert(pillViewController.pillView.bounds, to: rootView)

        XCTAssertLessThanOrEqual(pillFrame.width, 280, "The pill hugs its text instead of filling the window")
        XCTAssertLessThan(pillFrame.width, safeArea.width, "The pill hugs its text instead of filling the window")
        XCTAssertEqual(pillFrame.maxX, safeArea.maxX - WMFSpacing.small, accuracy: 0.5)
        XCTAssertEqual(pillFrame.minY, safeArea.minY + WMFSpacing.small, accuracy: 0.5)
    }
}
