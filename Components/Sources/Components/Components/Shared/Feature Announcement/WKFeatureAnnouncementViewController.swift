import Foundation

fileprivate final class WKFeatureAnnouncementHostingController: WKComponentHostingController<WKFeatureAnnouncementView> {

    init(viewModel: WKFeatureAnnouncementViewModel) {
        super.init(rootView: WKFeatureAnnouncementView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WKFeatureAnnouncementViewController: WKCanvasViewController {
    
    fileprivate let hostingViewController: WKFeatureAnnouncementHostingController
    
    public init(viewModel: WKFeatureAnnouncementViewModel) {
        self.hostingViewController = WKFeatureAnnouncementHostingController(viewModel: viewModel)
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
        view.backgroundColor = WKAppEnvironment.current.theme.popoverBackground
        hostingViewController.view.backgroundColor = WKAppEnvironment.current.theme.popoverBackground
    }
}
