import Foundation
import UIKit
import SwiftUI

fileprivate final class WMFYiR2026HostingController: WMFComponentHostingController<WMFYiR2026ContainerView> {
}

public final class WMFYiR2026ViewController: UIViewController {

    // MARK: - Properties

    private let hostingViewController: WMFYiR2026HostingController

    // MARK: - Lifecycle

    public init() {
        let viewModel = WMFYiR2026ViewModel()
        let containerView = WMFYiR2026ContainerView(viewModel: viewModel) { }
        self.hostingViewController = WMFYiR2026HostingController(rootView: containerView)
        super.init(nibName: nil, bundle: nil)
        // Patch the dismiss closure after init
        let dismissingView = WMFYiR2026ContainerView(viewModel: viewModel) { [weak self] in
            self?.dismiss(animated: true)
        }
        hostingViewController.rootView = dismissingView
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingViewController.didMove(toParent: self)
    }
}
