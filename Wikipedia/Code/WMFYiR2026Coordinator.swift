import UIKit
import SwiftUI
import WMFComponents
import Foundation

// MARK: - Coordinator

public final class WMFYiR2026Coordinator: NSObject {

    // MARK: Dependencies

    private weak var navigationController: UINavigationController?
    private let dataStore: MWKDataStore

    // MARK: Init

    public init(navigationController: UINavigationController, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        super.init()
    }

    // MARK: Public

    @MainActor public func start() {
        let viewModel = WMFYiR2026ViewModel()
        let hostingController = WMFYiR2026HostingController(viewModel: viewModel)
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        navigationController?.present(hostingController, animated: true)
    }
}

// MARK: - Hosting Controller

final class WMFYiR2026HostingController: UIViewController {

    private let viewModel: WMFYiR2026ViewModel

    init(viewModel: WMFYiR2026ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let rootView = WMFYiR2026ContainerView(viewModel: viewModel) { [weak self] in
            self?.dismiss(animated: true)
        }
        let child = UIHostingController(rootView: rootView)
        addChild(child)
        view.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        child.didMove(toParent: self)
    }
}
