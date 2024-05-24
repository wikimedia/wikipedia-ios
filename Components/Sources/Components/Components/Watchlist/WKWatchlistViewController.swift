import UIKit
import SwiftUI
import Combine
import WKData

public protocol WKWatchlistDelegate: AnyObject {
	func watchlistUserDidTapDiff(project: WKProject, title: String, revisionID: UInt, oldRevisionID: UInt)
	func watchlistUserDidTapUser(project: WKProject, title: String, revisionID: UInt, oldRevisionID: UInt, username: String, action: WKWatchlistUserButtonAction)
    func watchlistEmptyViewUserDidTapSearch()
	func watchlistUserDidTapAddLanguage(from: UIViewController, viewModel: WKWatchlistFilterViewModel)
}

public protocol WKWatchlistLoggingDelegate: AnyObject {
    func logWatchlistUserDidTapNavBarFilterButton()
    func logWatchlistUserDidSaveFilterSettings(filterSettings: WKWatchlistFilterSettings, onProjects: [WKProject])
    func logWatchlistUserDidTapUserButton(project: WKProject)
    func logWatchlistUserDidTapUserButtonAction(project: WKProject, action: WKWatchlistUserButtonAction)
    func logWatchlistEmptyViewDidShow(type: WKEmptyViewStateType)
    func logWatchlistEmptyViewUserDidTapSearch()
    func logWatchlistEmptyViewUserDidTapModifyFilters()
    func logWatchlistDidLoad(itemCount: Int)
}

public final class WKWatchlistViewController: WKCanvasViewController {

	// MARK: - Nested Types

	public enum PresentationState {
		case appearing
		case disappearing
	}

	public typealias ReachabilityHandler = ((PresentationState) -> Void)?

	class MenuButtonHandler: WKSmallMenuButtonDelegate {
		weak var watchlistDelegate: WKWatchlistDelegate?
        weak var watchlistLoggingDelegate: WKWatchlistLoggingDelegate?
		let menuButtonItems: [WKSmallMenuButton.MenuItem]
		let wkProjectMetadataKey: String
		let revisionIDMetadataKey: String
        let oldRevisionIDMetadataKey: String
        let articleTitleMetadataKey: String

        init(watchlistDelegate: WKWatchlistDelegate? = nil, watchlistLoggingDelegate: WKWatchlistLoggingDelegate?, menuButtonItems: [WKSmallMenuButton.MenuItem], wkProjectMetadataKey: String, revisionIDMetadataKey: String, oldRevisionIDMetadataKey: String, articleTitleMetadaKey: String) {
			self.watchlistDelegate = watchlistDelegate
            self.watchlistLoggingDelegate = watchlistLoggingDelegate
			self.menuButtonItems = menuButtonItems
			self.wkProjectMetadataKey = wkProjectMetadataKey
			self.revisionIDMetadataKey = revisionIDMetadataKey
            self.oldRevisionIDMetadataKey = oldRevisionIDMetadataKey
            self.articleTitleMetadataKey = articleTitleMetadaKey
		}

		func wkSwiftUIMenuButtonUserDidTap(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?) {
            guard let username = configuration.title, let tappedTitle = item?.title,
                    let wkProject = configuration.metadata[wkProjectMetadataKey] as? WKProject,
                  let revisionID = configuration.metadata[revisionIDMetadataKey] as? UInt,
                  let oldRevisionId = configuration.metadata[oldRevisionIDMetadataKey] as? UInt,
                  let title = configuration.metadata[articleTitleMetadataKey] as? String else {
                return
            }
            
            if item == nil {
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButton(project: wkProject)
            }


			guard menuButtonItems.indices.count == 4 else {
				fatalError("Unexpected number of menu button items")
			}

            if tappedTitle == menuButtonItems[0].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userPage)
                 watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userPage)
            } else if tappedTitle == menuButtonItems[1].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userTalkPage)
                 watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userTalkPage)
            } else if tappedTitle == menuButtonItems[2].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userContributions)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userContributions)
            } else if tappedTitle == menuButtonItems[3].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .thank(revisionID: revisionID))
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .thank(revisionID: revisionID))
            }
		}

        func wkSwiftUIMenuButtonUserDidTapAccessibility(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?) {
            guard let username = configuration.title, let tappedTitle = item?.title, 
                    let wkProject = configuration.metadata[wkProjectMetadataKey] as? WKProject,
                  let revisionID = configuration.metadata[revisionIDMetadataKey] as? UInt,
                  let oldRevisionId = configuration.metadata[oldRevisionIDMetadataKey] as? UInt,
                  let title = configuration.metadata[articleTitleMetadataKey] as? String else {
                return
            }

            guard menuButtonItems.indices.count == 5 else {
                fatalError("Unexpected number of menu button items")
            }
            if tappedTitle == menuButtonItems[0].title {
                watchlistDelegate?.watchlistUserDidTapDiff(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId)
            } else if tappedTitle == menuButtonItems[1].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userPage)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userPage)
            } else if tappedTitle == menuButtonItems[2].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userTalkPage)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userTalkPage)
            } else if tappedTitle == menuButtonItems[3].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .userContributions)
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .userContributions)
            } else if tappedTitle == menuButtonItems[4].title {
                watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, title: title, revisionID: revisionID, oldRevisionID: oldRevisionId, username: username, action: .thank(revisionID: revisionID))
                watchlistLoggingDelegate?.logWatchlistUserDidTapUserButtonAction(project: wkProject, action: .thank(revisionID: revisionID))
            }
        }
	}

	// MARK: - Properties

	fileprivate let hostingViewController: WKWatchlistHostingViewController
	let viewModel: WKWatchlistViewModel
    let filterViewModel: WKWatchlistFilterViewModel
    let emptyViewModel: WKEmptyViewModel
	weak var delegate: WKWatchlistDelegate?
    weak var loggingDelegate: WKWatchlistLoggingDelegate?
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

    public init(viewModel: WKWatchlistViewModel, filterViewModel: WKWatchlistFilterViewModel, emptyViewModel: WKEmptyViewModel, delegate: WKWatchlistDelegate?, loggingDelegate: WKWatchlistLoggingDelegate?, reachabilityHandler: ReachabilityHandler = nil) {
		self.viewModel = viewModel
        self.filterViewModel = filterViewModel
        self.emptyViewModel = emptyViewModel
		self.delegate = delegate
        self.loggingDelegate = loggingDelegate
		self.reachabilityHandler = reachabilityHandler

        let buttonHandler = MenuButtonHandler(watchlistDelegate: delegate, watchlistLoggingDelegate: loggingDelegate, menuButtonItems: viewModel.menuButtonItems, wkProjectMetadataKey: WKWatchlistViewModel.ItemViewModel.wkProjectMetadataKey, revisionIDMetadataKey: WKWatchlistViewModel.ItemViewModel.revisionIDMetadataKey, oldRevisionIDMetadataKey: WKWatchlistViewModel.ItemViewModel.oldRevisionIDMetadataKey, articleTitleMetadaKey: WKWatchlistViewModel.ItemViewModel.articleMetadataKey)
		self.buttonHandler = buttonHandler

        self.hostingViewController = WKWatchlistHostingViewController(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, menuButtonDelegate: buttonHandler)
		super.init()

        self.hostingViewController.emptyViewDelegate = self
        self.hostingViewController.loggingDelegate = loggingDelegate
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
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
		reachabilityHandler?(.disappearing)
        if viewModel.presentationConfiguration.hideNavBarUponDisappearance {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    public func showFilterView() {
		let filterView = WKWatchlistFilterView(viewModel: self.filterViewModel, doneAction: { [weak self] in
            self?.dismiss(animated: true)
        })

        self.present(WKWatchlistFilterHostingController(viewModel: self.filterViewModel, filterView: filterView, delegate: self), animated: true)
    }
}

fileprivate final class WKWatchlistHostingViewController: WKComponentHostingController<WKWatchlistView> {

	let viewModel: WKWatchlistViewModel
    let emptyViewModel: WKEmptyViewModel
    weak var emptyViewDelegate: WKEmptyViewDelegate? = nil {
        didSet {
            rootView.emptyViewDelegate = emptyViewDelegate
        }
    }
    weak var loggingDelegate: WKWatchlistLoggingDelegate? = nil {
        didSet {
            rootView.loggingDelegate = loggingDelegate
        }
    }

    init(viewModel: WKWatchlistViewModel, emptyViewModel: WKEmptyViewModel, delegate: WKWatchlistDelegate?, menuButtonDelegate: WKSmallMenuButtonDelegate?) {
		self.viewModel = viewModel
        self.emptyViewModel = emptyViewModel
        super.init(rootView: WKWatchlistView(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, loggingDelegate: loggingDelegate, menuButtonDelegate: menuButtonDelegate))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension WKWatchlistViewController: WKWatchlistFilterDelegate {

    func watchlistFilterDidChange(_ hostingController: WKWatchlistFilterHostingController) {
        viewModel.fetchWatchlist()
    }

	func watchlistFilterDidTapAddLanguage(_ hostingController: WKWatchlistFilterHostingController, viewModel: WKWatchlistFilterViewModel) {
		delegate?.watchlistUserDidTapAddLanguage(from: hostingController, viewModel: viewModel)		
	}
	
}

extension WKWatchlistViewController: WKEmptyViewDelegate {
    public func emptyViewDidShow(type: WKEmptyViewStateType) {
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
