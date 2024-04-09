import UIKit
import SwiftUI

public protocol WKSandboxListDelegate: AnyObject {
    func didTapSandboxTitle(title: String)
}

final class WKSandboxHostingViewController: WKComponentHostingController<SandboxView> {

    init(username: String, delegate: WKSandboxListDelegate) {
        super.init(rootView: SandboxView(username: username, delegate: delegate))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WKSandboxViewController: WKCanvasViewController {
    let hostingViewController: WKSandboxHostingViewController
    
    public init(username: String, delegate: WKSandboxListDelegate) {
        hostingViewController = WKSandboxHostingViewController(username: username, delegate: delegate)
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
