import Foundation
import UIKit

fileprivate final class WMFDeveloperSettingsHostingController: WMFComponentHostingController<WMFDeveloperSettingsView> {
    
}

@objc public final class WMFDeveloperSettingsViewController: WMFCanvasViewController {
    
    // MARK: - Properties

    private let hostingViewController: WMFDeveloperSettingsHostingController
    private let viewModel: WMFDeveloperSettingsViewModel
    
    // MARK: - Lifecycle
    
    @objc public init(viewModel: WMFDeveloperSettingsViewModel) {
        
        self.viewModel = viewModel
        let view = WMFDeveloperSettingsView(viewModel: viewModel)
        self.hostingViewController = WMFDeveloperSettingsHostingController(rootView: view)
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
