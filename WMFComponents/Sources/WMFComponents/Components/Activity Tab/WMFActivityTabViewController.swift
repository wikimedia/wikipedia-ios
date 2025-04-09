import UIKit

final class WMFActivityTabHostingController: WMFComponentHostingController<WMFActivityView> {

}

public final class WMFActivityTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let hostingViewController: WMFActivityTabHostingController

     @objc public override init() {
         let testItems = [
            ActivityItem(imageName: "pencil", title: "You edited 1 article this week.", subtitle: "Edit activity increased by 100% compared to the previous week.", onViewTitle: "View editing history", onViewTap: { print("On view tap")}),
            ActivityItem(imageName: "square.text.square", title: "You read 87 articles this week.", subtitle: "You read 12% less compared to the previous week.", onViewTitle: "View reading history", onViewTap: { print("On view tap")}),
            ActivityItem(imageName: "bookmark.fill", title: "You saved 8 articles this week", subtitle: "You saved 5 less articles compared to the previous week.", onViewTitle: "View saved articles", onViewTap: { print("On view tap")})
         ]
         let viewModel = WMFActivityViewModel(activityItems: testItems, shouldShowAddAnImage: false, shouldShowStartEditing: false, hasNoEdits: false)
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
        let titleConfig = WMFNavigationBarTitleConfig(title: "Activity", customView: nil, alignment: .leadingLarge)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}
