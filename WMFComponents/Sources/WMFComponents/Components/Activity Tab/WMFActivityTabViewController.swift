import UIKit

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityView> {

}

@objc public final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
    public let viewModel: WMFActivityViewModel
    public let showSurvey: () -> Void
    
    public init(viewModel: WMFActivityViewModel, showSurvey: @escaping () -> Void) {
        self.viewModel = viewModel
        self.showSurvey = showSurvey
        let view = WMFActivityView(viewModel: viewModel)
        self.hostingViewController = WMFActivityTabHostingController(rootView: view)
        super.init()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController

    public override func viewDidLoad() {
        super.viewDidLoad()

        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let defaults = UserDefaults.standard
        let key = "viewedActivityTab"
        
        if defaults.object(forKey: key) == nil {
            defaults.set(1, forKey: key)
        } else {
            let currentValue = defaults.integer(forKey: key)
            if currentValue == 1 {
                defaults.set(2, forKey: key)
                showSurvey()
            }
        }
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.tabTitle, customView: nil, alignment: .leadingCompact)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}
