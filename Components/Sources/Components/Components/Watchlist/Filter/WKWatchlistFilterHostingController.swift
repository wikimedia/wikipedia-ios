import Foundation
import SwiftUI

protocol WKWatchlistFilterDelegate: AnyObject {
    func watchlistFilterDidChange(_ hostingController: WKWatchlistFilterHostingController)
}

class WKWatchlistFilterHostingController: WKComponentHostingController<WKWatchlistFilterView> {
    
    private let viewModel: WKWatchlistFilterViewModel
    private weak var delegate: WKWatchlistFilterDelegate?
    
    public init(viewModel: WKWatchlistFilterViewModel, filterView: WKWatchlistFilterView, delegate: WKWatchlistFilterDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(rootView: filterView)
        self.overrideUserInterfaceStyle = viewModel.overrideUserInterfaceStyle
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.saveNewFilterSettings()
        delegate?.watchlistFilterDidChange(self)
    }
}
