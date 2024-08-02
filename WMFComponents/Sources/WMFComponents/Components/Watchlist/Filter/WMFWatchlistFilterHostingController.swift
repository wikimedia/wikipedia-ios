import Foundation
import SwiftUI

protocol WKWatchlistFilterDelegate: AnyObject {
    func watchlistFilterDidChange(_ hostingController: WMFWatchlistFilterHostingController)
	func watchlistFilterDidTapAddLanguage(_ hostingController: WMFWatchlistFilterHostingController, viewModel: WKWatchlistFilterViewModel)
}

class WMFWatchlistFilterHostingController: WKComponentHostingController<WKWatchlistFilterView> {
    
    private let viewModel: WKWatchlistFilterViewModel
    private weak var delegate: WKWatchlistFilterDelegate?
    
    public init(viewModel: WKWatchlistFilterViewModel, filterView: WKWatchlistFilterView, delegate: WKWatchlistFilterDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(rootView: filterView)
        self.overrideUserInterfaceStyle = viewModel.overrideUserInterfaceStyle

		filterView.viewModel.addLanguageAction = { [weak self, weak viewModel] in
			guard let self = self, let viewModel = viewModel else { return }
			self.delegate?.watchlistFilterDidTapAddLanguage(self, viewModel: viewModel)
		}
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.saveNewFilterSettings()
        delegate?.watchlistFilterDidChange(self)
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
	
}
