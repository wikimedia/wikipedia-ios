import UIKit
import SwiftUI
import Combine

public protocol WKWatchlistDelegate: AnyObject {
	func watchlistDidDismiss()
	func watchlistDidTapDiff()
}

public final class WKWatchlistViewController: WKCanvasViewController {

	// MARK: - Properties

	fileprivate let hostingViewController: WKWatchlistHostingViewController
	let viewModel: WKWatchlistViewModel
    let filterViewModel: WKWatchlistFilterViewModel
	weak var delegate: WKWatchlistDelegate?

	fileprivate lazy var filterBarButton = {
        let action = UIAction { [weak self] _ in
            guard let self else {
                return
            }
            
            var filterView = WKWatchlistFilterView(viewModel: filterViewModel, doneAction: { [weak self] in
                self?.dismiss(animated: true)
            })
            
            self.present(WKWatchlistFilterHostingController(viewModel: self.filterViewModel, filterView: filterView, delegate: self), animated: true)
        }
        let barButton = UIBarButtonItem(title: viewModel.localizedStrings.filter, primaryAction: action)
		return barButton
	}()
    
    private var subscribers: Set<AnyCancellable> = []

	// MARK: - Lifecycle

    public init(viewModel: WKWatchlistViewModel, filterViewModel: WKWatchlistFilterViewModel, delegate: WKWatchlistDelegate?) {
		self.viewModel = viewModel
        self.filterViewModel = filterViewModel
		self.delegate = delegate
		self.hostingViewController = WKWatchlistHostingViewController(viewModel: viewModel, delegate: delegate)
		super.init()
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
            
        }.store(in: &subscribers)
	}

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.presentationConfiguration.showNavBarUponAppearance {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if viewModel.presentationConfiguration.hideNavBarUponDisappearance {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
}

fileprivate final class WKWatchlistHostingViewController: WKComponentHostingController<WKWatchlistView> {

	let viewModel: WKWatchlistViewModel

	init(viewModel: WKWatchlistViewModel, delegate: WKWatchlistDelegate?) {
		self.viewModel = viewModel
		super.init(rootView: WKWatchlistView(viewModel: viewModel, delegate: delegate))
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
