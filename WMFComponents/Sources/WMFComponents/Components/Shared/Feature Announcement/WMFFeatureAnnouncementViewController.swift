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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = WMFAppEnvironment.current.theme.popoverBackground
        hostingViewController.view.backgroundColor = WMFAppEnvironment.current.theme.popoverBackground
    }
}
