import UIKit
import WMF
import CocoaLumberjackSwift

final class TalkPageCoffeeRollViewController: ThemeableViewController {

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
        // scrollView = coffeeRollView.scrollView
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

        navigationItem.title = TalkPageViewController.TalkPageLocalizedStrings.title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = false
        navigationItem.largeTitleDisplayMode = .never
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
