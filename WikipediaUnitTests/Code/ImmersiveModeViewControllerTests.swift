import UIKit
import XCTest
import WMFComponents
@testable import Wikipedia

/// Covers app-owned status-bar presenters and cached layout after the preference changes.
@MainActor
final class ImmersiveModeViewControllerTests: XCTestCase {

	func testAppRootFollowsImmersiveModeChanges() {
		let environment = WMFAppEnvironment.current
		let originalValue = environment.isImmersiveModeEnabled
		defer { environment.set(isImmersiveModeEnabled: originalValue) }
		let controller = WMFAppViewController()

		environment.set(isImmersiveModeEnabled: false)
		XCTAssertFalse(controller.prefersStatusBarHidden)

		environment.set(isImmersiveModeEnabled: true)
		XCTAssertTrue(controller.prefersStatusBarHidden)
		XCTAssertNil(controller.childForStatusBarHidden)

		environment.set(isImmersiveModeEnabled: false)
		XCTAssertFalse(controller.prefersStatusBarHidden)
	}

	func testDescriptionOnboardingFollowsImmersiveModeChanges() {
		let environment = WMFAppEnvironment.current
		let originalValue = environment.isImmersiveModeEnabled
		defer { environment.set(isImmersiveModeEnabled: originalValue) }
		let controller = DescriptionWelcomeInitialViewController()

		environment.set(isImmersiveModeEnabled: true)
		XCTAssertTrue(controller.prefersStatusBarHidden)

		environment.set(isImmersiveModeEnabled: false)
		XCTAssertFalse(controller.prefersStatusBarHidden)
	}

	func testGalleryKeepsStatusBarHiddenWithVisibleControls() {
		let environment = WMFAppEnvironment.current
		let originalValue = environment.isImmersiveModeEnabled
		defer { environment.set(isImmersiveModeEnabled: originalValue) }
		let controller = makeGallery()

		environment.set(isImmersiveModeEnabled: false)
		XCTAssertFalse(controller.prefersStatusBarHidden)

		environment.set(isImmersiveModeEnabled: true)
		XCTAssertTrue(controller.prefersStatusBarHidden)

		environment.set(isImmersiveModeEnabled: false)
		XCTAssertFalse(controller.prefersStatusBarHidden)
	}

	func testGalleryPreservesItsExistingHiddenStatusWhenImmersiveModeIsDisabled() {
		let environment = WMFAppEnvironment.current
		let originalValue = environment.isImmersiveModeEnabled
		defer { environment.set(isImmersiveModeEnabled: originalValue) }
		environment.set(isImmersiveModeEnabled: false)
		let controller = makeGallery()

		// The vendored viewer stores this state privately when the user hides its controls.
		controller.setValue(true, forKey: "statusBarHidden")
		XCTAssertTrue(controller.prefersStatusBarHidden)
	}

	func testSafeAreaChangeRefreshesExistingStatusBarOverlay() {
		let controller = OverlayTestViewController()
		controller.loadViewIfNeeded()
		let constraint = controller.view.heightAnchor.constraint(equalToConstant: 20)
		controller.topSafeAreaOverlayHeightConstraint = constraint

		// A detached view has no status-bar frame. A stale, visible-bar height must be cleared.
		controller.viewSafeAreaInsetsDidChange()

		XCTAssertEqual(constraint.constant, 0)
	}

	/// An empty gallery exercises the app override without fetching image data.
	private func makeGallery() -> WMFImageGalleryViewController {
		WMFImageGalleryViewController(photos: [], initialPhoto: nil, delegate: nil, theme: Theme.light, overlayViewTopBarHidden: false)
	}
}

/// Keeps the collection controller's layout callbacks while excluding unrelated feed setup.
@MainActor
private final class OverlayTestViewController: ColumnarCollectionViewController {
	override func loadView() {
		view = UIView()
	}

	override func viewDidLoad() {}

	override func scrollViewInsetsDidChange() {}
}
