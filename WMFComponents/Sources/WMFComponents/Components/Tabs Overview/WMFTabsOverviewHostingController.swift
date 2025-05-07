import SwiftUI

fileprivate final class WMFTabsOverviewHostingController: WMFComponentHostingController<WMFTabsOverviewView> {
    
}

@objc public final class WMFTabsOverviewViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
    // MARK: - Properties

    private let hostingViewController: WMFTabsOverviewHostingController
    private let viewModel: WMFTabsOverviewViewModel
    
    lazy var addTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .add), style: .plain, target: self, action: #selector(tappedAdd))
        return button
    }()
    
    // MARK: - Lifecycle
    
    public init(viewModel: WMFTabsOverviewViewModel) {
        self.viewModel = viewModel
        let view = WMFTabsOverviewView(viewModel: viewModel)
        self.hostingViewController = WMFTabsOverviewHostingController(rootView: view)
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
        
        navigationItem.rightBarButtonItem = addTabButton
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "Tabs", customView: nil, alignment: .centerCompact)
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: "Done", target: self, action: #selector(tappedClose), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc private func tappedClose() {
        dismiss(animated: true)
    }
    
    @objc private func tappedAdd() {
        viewModel.didTapAddTab()
    }
    
}
