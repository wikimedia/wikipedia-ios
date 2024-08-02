import Foundation
import UIKit

fileprivate final class WKDeveloperSettingsHostingController: WKComponentHostingController<WKDeveloperSettingsView> {
    
}

@objc public final class WKDeveloperSettingsViewController: WKCanvasViewController {
    
    // MARK: - Properties

    private let hostingViewController: WKDeveloperSettingsHostingController
    private let viewModel: WKDeveloperSettingsViewModel
    
    // MARK: - Lifecycle
    
    @objc public init(viewModel: WKDeveloperSettingsViewModel) {
        
        self.viewModel = viewModel
        let view = WKDeveloperSettingsView(viewModel: viewModel)
        self.hostingViewController = WKDeveloperSettingsHostingController(rootView: view)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = viewModel.localizedStrings.developerSettings
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.localizedStrings.close, style: .plain, target: self, action: #selector(tappedClose))
        
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}
