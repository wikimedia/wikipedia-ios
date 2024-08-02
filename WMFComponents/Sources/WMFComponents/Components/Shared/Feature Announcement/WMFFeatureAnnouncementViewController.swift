import Foundation

fileprivate final class WMFFeatureAnnouncementHostingController: WMFComponentHostingController<WMFFeatureAnnouncementView> {

    init(viewModel: WMFFeatureAnnouncementViewModel) {
        super.init(rootView: WMFFeatureAnnouncementView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WMFFeatureAnnouncementViewController: WMFCanvasViewController {
    
    fileprivate let hostingViewController: WMFFeatureAnnouncementHostingController
    
    public init(viewModel: WMFFeatureAnnouncementViewModel) {
        self.hostingViewController = WMFFeatureAnnouncementHostingController(viewModel: viewModel)
        super.init()
        self.preferredContentSize = CGSize(width: 278, height: 450)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func appEnvironmentDidChange() {
        view.backgroundColor = WMFAppEnvironment.current.theme.popoverBackground
        hostingViewController.view.backgroundColor = WMFAppEnvironment.current.theme.popoverBackground
    }
}
