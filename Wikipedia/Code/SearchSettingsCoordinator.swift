import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFData
import CocoaLumberjackSwift

/// Pushes the Search settings screen. Settings opens it from its Search row, and the search
/// screen opens it from the toast shown after the reader hides the semantic search entry point.
@MainActor
final class SearchSettingsCoordinator: Coordinator {

    // MARK: Coordinator Protocol Properties

    internal var navigationController: UINavigationController

    // MARK: Properties

    private let dataController: WMFSettingsDataController
    private let semanticSearchDataController: WMFSemanticSearchDataController

    // MARK: Lifecycle

    init(
        navigationController: UINavigationController,
        dataController: WMFSettingsDataController = WMFSettingsDataController.shared,
        semanticSearchDataController: WMFSemanticSearchDataController = WMFSemanticSearchDataController.shared
    ) {
        self.navigationController = navigationController
        self.dataController = dataController
        self.semanticSearchDataController = semanticSearchDataController
    }

    // MARK: Coordinator Protocol Methods

    @discardableResult
    func start() -> Bool {
        let dataController = dataController
        let semanticSearchDataController = semanticSearchDataController

        let viewModel = WMFSearchSettingsViewModel(
            showLanguageBar: dataController.showSearchLanguageBar(),
            openAppOnSearchTab: dataController.openAppOnSearchTab(),
            showsSemanticSearchItem: semanticSearchDataController.isSettingsEntryAvailable,
            showSemanticSearchEntryPoint: !semanticSearchDataController.isEntryPointHidden,
            userDefaultsStore: WMFDataEnvironment.current.userDefaultsStore,
            onToggleShowLanguageBar: { newValue in
                dataController.setShowSearchLanguageBar(newValue)
            },
            onToggleOpenAppOnSearchTab: { newValue in
                dataController.setOpenAppOnSearchTab(newValue)
            },
            onToggleShowSemanticSearchEntryPoint: { newValue in
                do {
                    try semanticSearchDataController.setEntryPointHidden(!newValue)
                } catch {
                    DDLogError("Updating the semantic search entry point visibility from Settings failed: \(error)")
                }
            }
        )

        let rootView = WMFSearchSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.title = viewModel.title
        navigationController.pushViewController(hostingController, animated: true)

        return true
    }
}
