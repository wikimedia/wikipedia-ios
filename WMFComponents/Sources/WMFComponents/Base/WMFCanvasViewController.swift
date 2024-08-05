import UIKit
import SwiftUI

/// A base `UIKit` WMFCanvasViewController to add WMFComponents to that automatically subscribes to `AppEnvironment` changes
open class WMFCanvasViewController: WMFComponentViewController {

	// MARK: - Properties

	public var canvas: WMFCanvas = {
		let canvas = WMFCanvas()
		canvas.translatesAutoresizingMaskIntoConstraints = false
		return canvas
	}()

	// MARK: - Lifecycle

	public override func loadView() {
		self.view = UIView()
		addComponent(canvas, pinToEdges: true)
	}

	// MARK: - Utility

	public func addComponent(_ componentView: WMFComponentView, pinToEdges: Bool = false, respectSafeArea: Bool = false) {
		view.addSubview(componentView)

		if pinToEdges {
			NSLayoutConstraint.activate([
				componentView.topAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor),
				componentView.bottomAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor),
				componentView.leadingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.leadingAnchor : view.leadingAnchor),
				componentView.trailingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.trailingAnchor : view.trailingAnchor)
			])
		}
	}

	public func addComponent<HostedView: View>(_ hostingController: WMFComponentHostingController<HostedView>, pinToEdges: Bool = false, respectSafeArea: Bool = false) {
		addComponent(hostingController)

		if pinToEdges {
			NSLayoutConstraint.activate([
				hostingController.view.topAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor),
				hostingController.view.bottomAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor),
				hostingController.view.leadingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.leadingAnchor : view.leadingAnchor),
				hostingController.view.trailingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.trailingAnchor : view.trailingAnchor)
			])
		}
	}

	public func addComponent(_ componentViewController: WMFComponentViewController, pinToEdges: Bool = false, respectSafeArea: Bool = false) {
		addComponent(componentViewController)

		if pinToEdges {
			NSLayoutConstraint.activate([
				componentViewController.view.topAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor),
				componentViewController.view.bottomAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor),
				componentViewController.view.leadingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.leadingAnchor : view.leadingAnchor),
				componentViewController.view.trailingAnchor.constraint(equalTo: respectSafeArea ? view.safeAreaLayoutGuide.trailingAnchor : view.trailingAnchor)
			])
		}
	}

	public func addComponent<HostedView: View>(_ hostingController: WMFComponentHostingController<HostedView>, to stackView: UIStackView) {
		addChild(hostingController)
		stackView.addArrangedSubview(hostingController.view)
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		hostingController.didMove(toParent: self)
	}

	private func addComponent(_ componentViewController: WMFComponentViewController) {
		addChild(componentViewController)
		view.addSubview(componentViewController.view)
		componentViewController.view.translatesAutoresizingMaskIntoConstraints = false
		componentViewController.didMove(toParent: self)
	}

	private func addComponent<HostedView: View>(_ hostingController: WMFComponentHostingController<HostedView>) {
		addChild(hostingController)
		view.addSubview(hostingController.view)
		hostingController.view.translatesAutoresizingMaskIntoConstraints = false
		hostingController.didMove(toParent: self)
	}

}
