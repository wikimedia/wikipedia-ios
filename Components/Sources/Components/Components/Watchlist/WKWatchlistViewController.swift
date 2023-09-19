import UIKit
import SwiftUI
import Combine
import WKData

public protocol WKWatchlistDelegate: AnyObject {
	func watchlistDidDismiss()
    func emptyViewDidTapSearch()
	func watchlistUserDidTapDiff(project: WKProject, title: String, revisionID: UInt, oldRevisionID: UInt)
	func watchlistUserDidTapUser(project: WKProject, username: String, action: WKWatchlistUserButtonAction)

}

public final class WKWatchlistViewController: WKCanvasViewController {

	// MARK: - Nested Types

	public enum PresentationState {
		case appearing
		case disappearing
	}

	public typealias ReachabilityHandler = ((PresentationState) -> ())?

	class MenuButtonHandler: WKMenuButtonDelegate {
		weak var watchlistDelegate: WKWatchlistDelegate?
		let menuButtonItems: [WKMenuButton.MenuItem]
		let wkProjectMetadataKey: String
		let revisionIDMetadataKey: String

		init(watchlistDelegate: WKWatchlistDelegate? = nil, menuButtonItems: [WKMenuButton.MenuItem], wkProjectMetadataKey: String, revisionIDMetadataKey: String) {
			self.watchlistDelegate = watchlistDelegate
			self.menuButtonItems = menuButtonItems
			self.wkProjectMetadataKey = wkProjectMetadataKey
			self.revisionIDMetadataKey = revisionIDMetadataKey
		}

		func wkSwiftUIMenuButtonUserDidTap(configuration: WKMenuButton.Configuration, item: WKMenuButton.MenuItem?) {
			guard let username = configuration.title, let tappedTitle = item?.title, let wkProject = configuration.metadata[wkProjectMetadataKey] as? WKProject else {
				return
			}

			guard menuButtonItems.indices.count == 4 else {
				fatalError("Unexpected number of menu button items")
			}

			if tappedTitle == menuButtonItems[0].title {
				watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, username: username, action: .userPage)
			} else if tappedTitle == menuButtonItems[1].title {
				watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, username: username, action: .userTalkPage)
			} else if tappedTitle == menuButtonItems[2].title {
				watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, username: username, action: .userContributions)
			} else if tappedTitle == menuButtonItems[3].title, let revisionID = configuration.metadata[revisionIDMetadataKey] as? UInt {
				watchlistDelegate?.watchlistUserDidTapUser(project: wkProject, username: username, action: .thank(revisionID: revisionID))
			}
		}
	}

	// MARK: - Properties

	fileprivate let hostingViewController: WKWatchlistHostingViewController
	let viewModel: WKWatchlistViewModel
    let filterViewModel: WKWatchlistFilterViewModel
    let emptyViewModel: WKEmptyViewModel
	weak var delegate: WKWatchlistDelegate?
	var reachabilityHandler: ReachabilityHandler
	let buttonHandler: MenuButtonHandler?

	fileprivate lazy var filterBarButton = {
        let action = UIAction { [weak self] _ in
            guard let self else {
                return
            }
            
            self.showFilterView()
        }
        let barButton = UIBarButtonItem(title: viewModel.localizedStrings.filter, primaryAction: action)
		return barButton
	}()
    
    private var subscribers: Set<AnyCancellable> = []

	// MARK: - Lifecycle

	public init(viewModel: WKWatchlistViewModel, filterViewModel: WKWatchlistFilterViewModel, emptyViewModel: WKEmptyViewModel, delegate: WKWatchlistDelegate?, reachabilityHandler: ReachabilityHandler = nil) {
		self.viewModel = viewModel
        self.filterViewModel = filterViewModel
        self.emptyViewModel = emptyViewModel
		self.delegate = delegate
		self.reachabilityHandler = reachabilityHandler

		let buttonHandler = MenuButtonHandler(watchlistDelegate: delegate, menuButtonItems: viewModel.menuButtonItems, wkProjectMetadataKey: WKWatchlistViewModel.ItemViewModel.wkProjectMetadataKey, revisionIDMetadataKey: WKWatchlistViewModel.ItemViewModel.revisionIDMetadataKey)
		self.buttonHandler = buttonHandler

        self.hostingViewController = WKWatchlistHostingViewController(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, menuButtonDelegate: buttonHandler)
		super.init()

        self.hostingViewController.emptyViewDelegate = self
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
        let filterView = WKWatchlistFilterView(viewModel: filterViewModel, doneAction: { [weak self] in
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

    init(viewModel: WKWatchlistViewModel, emptyViewModel: WKEmptyViewModel, delegate: WKWatchlistDelegate?, menuButtonDelegate: WKMenuButtonDelegate?) {
		self.viewModel = viewModel
        self.emptyViewModel = emptyViewModel
        super.init(rootView: WKWatchlistView(viewModel: viewModel, emptyViewModel: emptyViewModel, delegate: delegate, menuButtonDelegate: menuButtonDelegate))
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension WKWatchlistViewController: WKWatchlistFilterDelegate {
    func watchlistFilterDidChange(_ hostingController: WKWatchlistFilterHostingController) {
        viewModel.fetchWatchlist()
    }
}

extension WKWatchlistViewController: WKEmptyViewDelegate {
    public func didTapSearch() {
        delegate?.emptyViewDidTapSearch()
    }
    
    public func didTapFilters() {
        showFilterView()
    }
}
