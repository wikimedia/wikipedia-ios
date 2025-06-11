import Foundation
import UIKit

fileprivate final class WMFDeveloperSettingsHostingController: WMFComponentHostingController<WMFDeveloperSettingsView> {
    
}

@objc public final class WMFDeveloperSettingsViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
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

        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.developerSettings, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: viewModel.localizedStrings.done, target: self, action: #selector(tappedClose), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}
