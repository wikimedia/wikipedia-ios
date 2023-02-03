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
        return ShiftingNavigationBarView(shiftOrder: 1, navigationItems: items, hidesOnScroll: false, popDelegate: self)
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
        
        setup(shiftingTopViews: [barView], shadowBehavior: .show, swiftuiView: archivesView, observableTheme: observableTheme)

        apply(theme: observableTheme.theme)
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
