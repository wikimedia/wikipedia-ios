import UIKit
import WMF
import CocoaLumberjackSwift
import WMFComponents

final class TalkPageCoffeeRollViewController: ThemeableViewController, WMFNavigationBarConfiguring {

    // MARK: - Properties

    fileprivate let viewModel: TalkPageCoffeeRollViewModel

    var coffeeRollView: TalkPageCoffeeRollView {
        return view as! TalkPageCoffeeRollView
    }

    // MARK: - Lifecycle

    override func loadView() {
        let coffeeRollView = TalkPageCoffeeRollView(theme: theme, viewModel: viewModel, frame: UIScreen.main.bounds)
        view = coffeeRollView
        coffeeRollView.configure(viewModel: viewModel)
    }

    init(theme: Theme, viewModel: TalkPageCoffeeRollViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coffeeRollView.linkDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: TalkPageViewController.TalkPageLocalizedStrings.title, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        coffeeRollView.apply(theme: theme)
    }

}

extension TalkPageCoffeeRollViewController: TalkPageTextViewLinkHandling {

    func tappedLink(_ url: URL, sourceTextView: UITextView) {
        guard let url = URL(string: url.absoluteString, relativeTo: viewModel.talkPageURL) else {
            return
        }
        
        let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.talkPage.rawValue]
        navigate(to: url.absoluteURL, userInfo: userInfo)
    }
}
