import Foundation
import UIKit
import Combine

class TalkPageArchivesHostingContainingController: UIViewController, CustomNavigationContaining {
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: true, shiftOnScrollUp: true)
        return ShiftingNavigationBarView(order: 0, config: config, navigationItems: items, popDelegate: self)
    }()

    private let tempOldViewModel: TalkPageViewModel
    
    var navigationViewChildViewController: CustomNavigationChildViewController?
    
    init(theme: Theme, tempOldViewModel: TalkPageViewModel) {
        self.tempOldViewModel = tempOldViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view.")
        
        var rootView = TalkPageArchivesView(pageTitle: tempOldViewModel.pageTitle, siteURL: tempOldViewModel.siteURL)
        
        rootView.didTapItem = { item in
            self.didTapItem(item)
        }
        
        setup(shiftingSubviews: [barView], shadowBehavior: .showUponScroll, swiftuiView: rootView)
    }
    
    func didTapItem(_ item: TalkPageArchivesItem) {
        guard let viewModel = TalkPageViewModel(pageType: tempOldViewModel.pageType, pageTitle: item.title, siteURL: tempOldViewModel.siteURL, source: tempOldViewModel.source, articleSummaryController: tempOldViewModel.dataController.articleSummaryController, authenticationManager: tempOldViewModel.authenticationManager, languageLinkController: tempOldViewModel.languageLinkController) else {
            showGenericError()
            return
        }
        let vc = TalkPageViewController(viewModel: viewModel, theme: .light)
        navigationController?.pushViewController(vc, animated: true)
    }
}
