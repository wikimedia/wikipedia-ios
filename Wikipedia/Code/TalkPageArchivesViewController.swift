import Foundation
import UIKit
import SwiftUI
import Combine
import WMF
import WMFComponents

struct TalkPageArchivesViewModel {
    let siteURL: URL
    let pageTitle: String
    let pageType: TalkPageType
    let articleSummaryController: ArticleSummaryController
    let authenticationManager: WMFAuthenticationManager
    let languageLinkController: MWKLanguageLinkController
    let dataStore: MWKDataStore
    
    init(talkPageViewModel: TalkPageViewModel) {
        self.siteURL = talkPageViewModel.siteURL
        self.pageTitle = talkPageViewModel.pageTitle
        self.pageType = talkPageViewModel.pageType
        self.articleSummaryController = talkPageViewModel.dataController.articleSummaryController
        self.authenticationManager = talkPageViewModel.authenticationManager
        self.languageLinkController = talkPageViewModel.languageLinkController
        self.dataStore = talkPageViewModel.dataStore
    }
}

class TalkPageArchivesViewController: UIViewController, Themeable, WMFNavigationBarConfiguring {

    private let viewModel: TalkPageArchivesViewModel
    private var observableTheme: ObservableTheme

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

        let archivesView = TalkPageArchivesView(pageTitle: viewModel.pageTitle, siteURL: viewModel.siteURL, didTapItem: didTapItem)
        
        let finalSwiftUIView = archivesView
                    .environmentObject(observableTheme)
        
        let childHostingVC = UIHostingController(rootView: finalSwiftUIView)
        
        childHostingVC.view.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(childHostingVC.view)

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: childHostingVC.view.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: childHostingVC.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: childHostingVC.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childHostingVC.view.bottomAnchor)
        ])

        addChild(childHostingVC)
        childHostingVC.didMove(toParent: self)
        childHostingVC.view.backgroundColor = .clear

        apply(theme: observableTheme.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view."), customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    func apply(theme: Theme) {
        observableTheme.theme = theme
        view.backgroundColor = theme.colors.paperBackground
    }
    
    private func didTapItem(_ item: TalkPageArchivesItem) {
        guard let viewModel = TalkPageViewModel(pageType: viewModel.pageType, pageTitle: item.title, siteURL: viewModel.siteURL, source: .talkPageArchives, articleSummaryController: viewModel.articleSummaryController, authenticationManager: viewModel.authenticationManager, languageLinkController: viewModel.languageLinkController, dataStore: viewModel.dataStore) else {
                showGenericError()
                return
            }
        let vc = TalkPageViewController(theme: observableTheme.theme, viewModel: viewModel)
            navigationController?.pushViewController(vc, animated: true)
        }
}
