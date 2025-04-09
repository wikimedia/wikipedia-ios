import UIKit

 final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityTabView> {

}

public final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController

     @objc public override init() {
        let view = WMFActivityTabView()
        self.hostingViewController = WMFActivityTabHostingController(rootView: view)
        super.init()
    }
}
