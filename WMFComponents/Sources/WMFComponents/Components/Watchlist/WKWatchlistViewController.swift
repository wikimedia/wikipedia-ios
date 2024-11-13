import UIKit
import SwiftUI
import Combine
import WMFData

public protocol WMFWatchlistDelegate: AnyObject {
    func watchlistUserDidTapDiff(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt)
    func watchlistUserDidTapUser(project: WMFProject, title: String, revisionID: UInt, oldRevisionID: UInt, username: String, action: WMFWatchlistUserButtonAction)
    func watchlistEmptyViewUserDidTapSearch()
	func watchlistUserDidTapAddLanguage(from: UIViewController, viewModel: WMFWatchlistFilterViewModel)
}

public protocol WMFWatchlistLoggingDelegate: AnyObject {
    func logWatchlistUserDidTapNavBarFilterButton()
    func logWatchlistUserDidSaveFilterSettings(filterSettings: WMFWatchlistFilterSettings, onProjects: [WMFProject])
    func logWatchlistUserDidTapUserButton(project: WMFProject)
    func logWatchlistUserDidTapUserButtonAction(project: WMFProject, action: WMFWatchlistUserButtonAction)
    func logWatchlistEmptyViewDidShow(type: WMFEmptyViewStateType)
    func logWatchlistEmptyViewUserDidTapSearch()
    func logWatchlistEmptyViewUserDidTapModifyFilters()
    func logWatchlistDidLoad(itemCount: Int)
}

public final class WMFWatchlistViewController: WMFCanvasViewController {

	// MARK: - Nested Types

	public enum PresentationState {
		case appearing
		case disappearing
	}

	public typealias ReachabilityHandler = ((PresentationState) -> Void)?

    class MenuButtonHandler: WMFSmallMenuButtonDelegate {
        weak var watchlistDelegate: WMFWatchlistDelegate?
        weak var watchlistLoggingDelegate: WMFWatchlistLoggingDelegate?
        let menuButtonItems: [WMFSmallMenuButton.MenuItem]
        let wmfProjectMetadataKey: String
		let revisionIDMetadataKey: String
        let oldRevisionIDMetadataKey: String
        let articleTitleMetadataKey: String

        init(watchlistDelegate: WMFWatchlistDelegate? = nil, watchlistLoggingDelegate: WMFWatchlistLoggingDelegate?, menuButtonItems: [WMFSmallMenuButton.MenuItem], wmfProjectMetadataKey: String, revisionIDMetadataKey: String, oldRevisionIDMetadataKey: String, articleTitleMetadaKey: String) {
            self.watchlistDelegate = watchlistDelegate
            self.watchlistLoggingDelegate = watchlistLoggingDelegate
            self.menuButtonItems = menuButtonItems
            self.wmfProjectMetadataKey = wmfProjectMetadataKey
			self.revisionIDMetadataKey = revisionIDMetadataKey
            self.oldRevisionIDMetadataKey = oldRevisionIDMetadataKey
            self.articleTitleMetadataKey = articleTitleMetadaKey
		}

		func wmfSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {
            guard let username = configuration.title, let tappedTitle = item?.title,
                    let wmfProject = configuration.metadata[wmfProjectMetadataKey] as? WMFProject,
                  let revisionID = configuration.metadata[revisionIDMetadataKey] as? UInt,
                  let oldRevisionId = configuration.metadata[oldRevisionIDMetadataKey] as? UInt,
                  let title = configuration.metadata[articleTitleMetadataKey] as? String else {
                return
            }
            
            if item == nil {
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButton(project: wmfProject)
            }


			guard menuButtonItems.indices.count == 4 else {
				fatalError("Unexpected number of menu button items")
			}

            if tappedTitle == menuButtonItems[0].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userPage)
                 watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userPage)
            } else if tappedTitle == menuButtonItems[1].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userTalkPage)
                 watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userTalkPage)
            } else if tappedTitle == menuButtonItems[2].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userContributions)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userContributions)
            } else if tappedTitle == menuButtonItems[3].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .thank(revisionID: revisionID))
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .thank(revisionID: revisionID))
            }
		}

        func wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {
            guard let username = configuration.title, let tappedTitle = item?.title,
                    let wmfProject = configuration.metadata[wmfProjectMetadataKey] as? WMFProject,
                  let revisionID = configuration.metadata[revisionIDMetadataKey] as? UInt,
                  let oldRevisionId = configuration.metadata[oldRevisionIDMetadataKey] as? UInt,
                  let title = configuration.metadata[articleTitleMetadataKey] as? String else {
                return
            }

            guard menuButtonItems.indices.count == 5 else {
                fatalError("Unexpected number of menu button items")
            }
            if tappedTitle == menuButtonItems[0].title {
                watchlistDelegate?.watchlistUserDidTapDiff(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId)
            } else if tappedTitle == menuButtonItems[1].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userPage)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userPage)
            } else if tappedTitle == menuButtonItems[2].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userTalkPage)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userTalkPage)
            } else if tappedTitle == menuButtonItems[3].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userContributions)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .userContributions)
            } else if tappedTitle == menuButtonItems[4].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wmfProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .thank(revisionID: revisionID))
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wmfProject, action: .thank(revisionID: revisionID))
            }
        }
	}

	// MARK: - Properties

	fileprivate let hostingViewController: WMFWatchlistHostingViewController
	let viewModel: WMFWatchlistViewModel
    let filterViewModel: WMFWatchlistFilterViewModel
    let emptyViewModel: WMFEmptyViewModel
	weak var delegate: WMFWatchlistDelegate?
    weak var loggingDelegate: WMFWatchlistLoggingDelegate?
	var reachabilityHandler: ReachabilityHandler
	let buttonHandler: MenuButtonHandler?

	fileprivate lazy var filterBarButton = {
        let action = UIAction { [weak self] _ in
            guard let self else {
                return
            }

            loggingDelegate?.logWatchlistUserDidTapNavBarFilterButton()
            self.showFilterView()
        }
        let barButton = UIBarButtonItem(title: viewModel.localizedStrings.filter, primaryAction: action)
		return barButton
	}()
    
    private var subscribers: Set<AnyCancellable> = []

	// MARK: - Lifecycle

    public init(viewModel: WMFWatchlistViewModel, filterViewModel: WMFWatchlistFilterViewModel, emptyViewModel: WMFEmptyViewModel, delegate: WMFWatchlistDelegate?, loggingDelegate: WMFWatchlistLoggingDelegate?, reachabilityHandler: ReachabilityHandler = nil) {
		self.viewModel = viewModel
        self.filterViewModel = filterViewModel
        self.emptyViewModel = emptyViewModel
		self.delegate = delegate
        self.loggingDelegate = loggingDelegate
		self.reachabilityHandler = reachabilityHandler

        let buttonHandler = MenuButtonHandler(watchlistDelegate: delegate, watchlistLoggingDelegate: loggingDelegate, menuButtonItems: viewModel.menuButtonItems, wmfProjectMetadataKey: WMFWatchlistViewModel.ItemViewModel.wmfProjectMetadataKey, revisionIDMetadataKey: WMFWatchlistViewModel.ItemViewModel.revisionIDMetadataKey, oldRevisionIDMetadataKey: WMFWatchlistViewModel.ItemViewModel.oldRevisionIDMetadataKey, articleTitleMetadaKey: WMFWatchlistViewModel.ItemViewModel.articleMetadataKey)
		self.buttonHandler = buttonHandler

        self.hostingViewController = WMFWatchlistHostingViewController(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, menuButtonDelegate: buttonHandler)
		super.init()

        self.hostingViewController.emptyViewDelegate = self
        self.hostingViewController.loggingDelegate = loggingDelegate
        hidesBottomBarWhenPushed = true
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		addComponent(hostingViewController, pinToEdges: true)
		self.title = viewModel.localizedStrings.title
		navigationItem.rightBarButtonItem = filterBarButton
        viewModel.$activeFilterCount.sink { [weak self] newCount in
            guard let self else {
                return
            }
            
            self.filterBarButton.title =
                newCount == 0 ?
                self.viewModel.localizedStrings.filter :
                self.viewModel.localizedStrings.filter + " (\(newCount))"
            self.emptyViewModel.numberOfFilters = newCount
        }.store(in: &subscribers)
	}

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
		reachabilityHandler?(.appearing)
        if viewModel.presentationConfiguration.showNavBarUponAppearance {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
        
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fixes https://phabricator.wikimedia.org/T375445 caused by iPadOS18 floating tab bar
        if #available(iOS 18, *) {
            guard UIDevice.current.userInterfaceIdiom == .pad else {
                return
            }
            
            navigationController?.view.setNeedsLayout()
            navigationController?.view.layoutIfNeeded()
        }
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
		reachabilityHandler?(.disappearing)
        if viewModel.presentationConfiguration.hideNavBarUponDisappearance {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    public func showFilterView() {
		let filterView = WMFWatchlistFilterView(viewModel: self.filterViewModel, doneAction: { [weak self] in
            self?.dismiss(animated: true)
        })

        self.present(WMFWatchlistFilterHostingController(viewModel: self.filterViewModel, filterView: filterView, delegate: self), animated: true)
    }
}

fileprivate final class WMFWatchlistHostingViewController: WMFComponentHostingController<WMFWatchlistView> {

	let viewModel: WMFWatchlistViewModel
    let emptyViewModel: WMFEmptyViewModel
    weak var emptyViewDelegate: WMFEmptyViewDelegate? = nil {
        didSet {
            rootView.emptyViewDelegate = emptyViewDelegate
        }
    }
    weak var loggingDelegate: WMFWatchlistLoggingDelegate? = nil {
        didSet {
            rootView.loggingDelegate = loggingDelegate
        }
    }

    init(viewModel: WMFWatchlistViewModel, emptyViewModel: WMFEmptyViewModel, delegate: WMFWatchlistDelegate?, menuButtonDelegate: WMFSmallMenuButtonDelegate?) {
		self.viewModel = viewModel
        self.emptyViewModel = emptyViewModel
        super.init(rootView: WMFWatchlistView(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, loggingDelegate: loggingDelegate, menuButtonDelegate: menuButtonDelegate))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension WMFWatchlistViewController: WMFWatchlistFilterDelegate {

    func watchlistFilterDidChange(_ hostingController: WMFWatchlistFilterHostingController) {
        viewModel.fetchWatchlist()
    }

	func watchlistFilterDidTapAddLanguage(_ hostingController: WMFWatchlistFilterHostingController, viewModel: WMFWatchlistFilterViewModel) {
		delegate?.watchlistUserDidTapAddLanguage(from: hostingController, viewModel: viewModel)		
	}
	
}

extension WMFWatchlistViewController: WMFEmptyViewDelegate {
    public func emptyViewDidShow(type: WMFEmptyViewStateType) {
        loggingDelegate?.logWatchlistEmptyViewDidShow(type: type)
    }
    
    public func emptyViewDidTapSearch() {
        delegate?.watchlistEmptyViewUserDidTapSearch()
        loggingDelegate?.logWatchlistEmptyViewUserDidTapSearch()
    }
    
    public func emptyViewDidTapFilters() {
        showFilterView()
        loggingDelegate?.logWatchlistEmptyViewUserDidTapModifyFilters()
    }
}
