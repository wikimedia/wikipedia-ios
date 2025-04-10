import UIKit

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityView> {

}

public final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    @objc public init(viewModel: WMFActivityViewModel, isLoggedIn: Bool, openHistory: @escaping @convention(block) () -> Void) {
        let view = WMFActivityView(viewModel: viewModel, isLoggedIn: isLoggedIn)
         self.hostingViewController = WMFActivityTabHostingController(rootView: view)
         super.init()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController

    public init(viewModel: WMFActivityViewModel, isLoggedIn: Bool) {
        let view = WMFActivityView(viewModel: viewModel, isLoggedIn: isLoggedIn)
         self.hostingViewController = WMFActivityTabHostingController(rootView: view)
         super.init()
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
        let titleConfig = WMFNavigationBarTitleConfig(title: "Activity", customView: nil, alignment: .leadingLarge)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}
