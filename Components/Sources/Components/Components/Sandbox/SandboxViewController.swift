import UIKit
import SwiftUI

final class WKSandboxHostingViewController: WKComponentHostingController<SandboxView> {
    init() {
        super.init(rootView: SandboxView())
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WKSandboxViewController: WKCanvasViewController {
    let hostingViewController: WKSandboxHostingViewController

    public override init() {
        hostingViewController = WKSandboxHostingViewController()
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sandbox"
        navigationItem.backButtonDisplayMode = .generic
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

}
