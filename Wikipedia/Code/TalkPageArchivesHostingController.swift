import Foundation
import UIKit
import Combine

class TalkPageArchivesHostingContainingController: UIViewController, CustomNavigationContaining {
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: true, shiftOnScrollUp: true, needsProgressView: true)
        return ShiftingNavigationBarView(order: 0, config: config, navigationItems: items, popDelegate: self)
    }()

    private let viewModel: TalkPageArchivesViewModel
    private let tempOldViewModel: TalkPageViewModel
    private var isLoadingCancellable: AnyCancellable?
    
    var navigationViewChildViewController: CustomNavigationChildViewController?
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: barView, delegate: barView)
        progressController.delay = 0.0
        return progressController
    }()
    
    init(theme: Theme, viewModel: TalkPageArchivesViewModel, tempOldViewModel: TalkPageViewModel) {
        self.tempOldViewModel = tempOldViewModel
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view.")
        
        var rootView = TalkPageArchivesView(viewModel: viewModel)
        rootView.didTapItem = { item in
            self.didTapItem(item)
        }
        
        setup(shiftingSubviews: [barView], shadowBehavior: .showUponScroll, swiftuiView: rootView)
        
        self.isLoadingCancellable = viewModel.$isLoading.sink { [weak self] isLoading in
            
            guard let self = self else {
                return
            }
            
            if isLoading {
                self.fakeProgressController.start()
            } else {
                self.fakeProgressController.stop()
            }
        }
    }
    
    func didTapItem(_ item: TalkPageArchivesViewModel.Item) {
        guard let viewModel = TalkPageViewModel(pageType: tempOldViewModel.pageType, pageTitle: item.title, siteURL: viewModel.siteURL, source: tempOldViewModel.source, articleSummaryController: tempOldViewModel.dataController.articleSummaryController, authenticationManager: tempOldViewModel.authenticationManager, languageLinkController: tempOldViewModel.languageLinkController) else {
            showGenericError()
            return
        }
        let vc = TalkPageViewController(viewModel: viewModel, theme: .light)
        navigationController?.pushViewController(vc, animated: true)
    }
}
