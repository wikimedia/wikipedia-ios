import UIKit

@objc(WMFPageHistoryViewControllerDelegate)
protocol PageHistoryViewControllerDelegate: AnyObject {
    func pageHistoryViewControllerDidDisappear(_ pageHistoryViewController: PageHistoryViewController)
}

@objc(WMFPageHistoryViewController)
class PageHistoryViewController: ViewController {
    private let pageTitle: String
    private let pageURL: URL
    private let pageHistoryFetcher = PageHistoryFetcher()

    @objc public weak var delegate: PageHistoryViewControllerDelegate?

    private lazy var statsViewController = PageHistoryStatsViewController(pageTitle: pageTitle, locale: NSLocale.wmf_locale(for: pageURL.wmf_language))

    @objc init(pageTitle: String, pageURL: URL) {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("page-history-compare-title", value: "Compare", comment: "Title for action button that allows users to contrast different items"), style: .plain, target: self, action: #selector(compare(_:)))
        title = CommonStrings.historyTabTitle

        addChild(statsViewController)
        navigationBar.addUnderNavigationBarView(statsViewController.view)
        navigationBar.shadowColorKeyPath = \Theme.colors.border
        statsViewController.didMove(toParent: self)

        apply(theme: theme)

        // TODO: Move networking

        pageHistoryFetcher.fetchPageStats(pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let pageStats):
                DispatchQueue.main.async {
                    self.statsViewController.pageStats = pageStats
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.pageHistoryViewControllerDidDisappear(self)
    }

    @objc private func compare(_ sender: UIBarButtonItem) {

    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationItem.leftBarButtonItem?.tintColor = theme.colors.primaryText
        statsViewController.apply(theme: theme)
    }
}
