import Foundation
import UIKit
import Combine

class TalkPageArchivesHostingController: CustomNavigationViewHostingController<TalkPageArchivesView> {
    
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: true, shiftOnScrollUp: true, needsProgressView: true)
        return ShiftingNavigationBarView(order: 0, config: config, navigationItems: items, popDelegate: self)
    }()
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        return [barView]
    }
    
    // todo: can we hide some of this in superclass?
    override var data: CustomNavigationViewData {
        return _data
    }
    private let _data: CustomNavigationViewData
    private let viewModel: TalkPageArchivesViewModel
    private let tempOldViewModel: TalkPageViewModel
    private var isLoadingCancellable: AnyCancellable?
    
    lazy private(set) var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: barView, delegate: barView)
        progressController.delay = 0.0
        return progressController
    }()
    
    init(theme: Theme, viewModel: TalkPageArchivesViewModel, tempOldViewModel: TalkPageViewModel) {
        let data = CustomNavigationViewData()
        self._data = data
        self.tempOldViewModel = tempOldViewModel
        var rootView = TalkPageArchivesView(data: data, viewModel: viewModel)
        self.viewModel = viewModel
        super.init(rootView: rootView, theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.didTapItem = { item in
            self.didTapItem(item)
        }
        
        self.title = WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view.")
        
        apply(theme: theme)
        
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
        let vc = TalkPageViewController(viewModel: viewModel, theme: theme)
        navigationController?.pushViewController(vc, animated: true)
    }
}
