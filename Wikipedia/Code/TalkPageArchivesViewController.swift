import Foundation
import UIKit
import SwiftUI
import Combine
import WMF

struct TalkPageArchivesViewModel {
    let siteURL: URL
    let pageTitle: String
    let pageType: TalkPageType
    let articleSummaryController: ArticleSummaryController
    let authenticationManager: WMFAuthenticationManager
    let languageLinkController: MWKLanguageLinkController
    
    init(talkPageViewModel: TalkPageViewModel) {
        self.siteURL = talkPageViewModel.siteURL
        self.pageTitle = talkPageViewModel.pageTitle
        self.pageType = talkPageViewModel.pageType
        self.articleSummaryController = talkPageViewModel.dataController.articleSummaryController
        self.authenticationManager = talkPageViewModel.authenticationManager
        self.languageLinkController = talkPageViewModel.languageLinkController
    }
}

class TalkPageArchivesViewController: UIViewController, Themeable, ShiftingTopViewsContaining {

    private let viewModel: TalkPageArchivesViewModel
    private var observableTheme: ObservableTheme

    var shiftingTopViewsStack: ShiftingTopViewsStack?
    
    lazy var barView: ShiftingNavigationBarView = {
        let items = navigationController?.viewControllers.map({ $0.navigationItem }) ?? []
        return ShiftingNavigationBarView(shiftOrder: 1, navigationItems: items, hidesOnScroll: true, popDelegate: self)
    }()
    
    lazy var demoHeaderView: DemoShiftingThreeLineHeaderView = {
            return DemoShiftingThreeLineHeaderView(shiftOrder: 0, theme: observableTheme.theme)
        }()

    init(viewModel: TalkPageArchivesViewModel, theme: Theme) {
        self.viewModel = viewModel
        self.observableTheme = ObservableTheme(theme: theme)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view.")

        let archivesView = TalkPageArchivesView(pageTitle: viewModel.pageTitle, siteURL: viewModel.siteURL, didTapItem: didTapItem)
        
        setup(shiftingTopViews: [barView, demoHeaderView], shadowBehavior: .show, swiftuiView: archivesView, observableTheme: observableTheme)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

        apply(theme: observableTheme.theme)
    }
    
    @objc private func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            print("began")
        case .ended:
            print("ended")
        default:
            break
        }
    }

    func apply(theme: Theme) {
        observableTheme.theme = theme
        view.backgroundColor = theme.colors.paperBackground
        shiftingTopViewsStack?.apply(theme: theme)
    }
    
    private func didTapItem(_ item: TalkPageArchivesItem) {
        guard let viewModel = TalkPageViewModel(pageType: viewModel.pageType, pageTitle: item.title, siteURL: viewModel.siteURL, source: .talkPageArchives, articleSummaryController: viewModel.articleSummaryController, authenticationManager: viewModel.authenticationManager, languageLinkController: viewModel.languageLinkController) else {
                showGenericError()
                return
            }
        let vc = TalkPageViewController(theme: observableTheme.theme, viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        }
}

extension TalkPageArchivesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class DemoShiftingThreeLineHeaderView: ShiftingTopView, Themeable {

    private(set) var theme: Theme

    private lazy var headerView: ThreeLineHeaderView = {
        let view = ThreeLineHeaderView()
        view.topSmallLine.text = "Test 1"
        view.middleLargeLine.text = "Test 2"
        view.bottomSmallLine.text = "Test 3"
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var topConstraint: NSLayoutConstraint?

    init(shiftOrder: Int, theme: Theme) {
        self.theme = theme
        super.init(shiftOrder: shiftOrder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        addSubview(headerView)

        let top = headerView.topAnchor.constraint(equalTo: topAnchor)
        let bottom = bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        let leading = headerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = trailingAnchor.constraint(equalTo: headerView.trailingAnchor)

        NSLayoutConstraint.activate([
            top,
            bottom,
            leading,
            trailing
        ])

        self.topConstraint = top
        clipsToBounds = true
        apply(theme: theme)
    }

    // MARK: Overrides
    
    override var contentHeight: CGFloat {
        return headerView.frame.height
    }

    private var isFullyHidden: Bool {
       return -(topConstraint?.constant ?? 0) == contentHeight
    }

    override func shift(amount: CGFloat) -> ShiftingTopView.AmountShifted {

        let limitedShiftAmount = max(0, min(amount, contentHeight))

        let percent = limitedShiftAmount / contentHeight
        alpha = 1.0 - percent

        if (self.topConstraint?.constant ?? 0) != -limitedShiftAmount {
            self.topConstraint?.constant = -limitedShiftAmount
        }

        return limitedShiftAmount
    }

    // MARK: Themeable
    
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        headerView.apply(theme: theme)
    }
}
