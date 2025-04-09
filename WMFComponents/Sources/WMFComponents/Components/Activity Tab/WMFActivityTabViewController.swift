import UIKit

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityView> {

}

public final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController

     @objc public override init() {
         let viewModel = WMFActivityViewModel(activityItems: nil, shouldShowAddAnImage: false, shouldShowStartEditing: false, hasNoEdits: false)
         let view = WMFActivityView(viewModel: viewModel)
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
        let titleConfig = WMFNavigationBarTitleConfig(title: "Activity tab", customView: nil, alignment: .leadingLarge)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}
