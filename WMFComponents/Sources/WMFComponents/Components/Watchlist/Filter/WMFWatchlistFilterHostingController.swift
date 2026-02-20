import Foundation
import SwiftUI

protocol WMFWatchlistFilterDelegate: AnyObject {
    func watchlistFilterDidChange(_ hostingController: WMFWatchlistFilterHostingController)
	func watchlistFilterDidTapAddLanguage(_ hostingController: WMFWatchlistFilterHostingController, viewModel: WMFWatchlistFilterViewModel)
}

class WMFWatchlistFilterHostingController: WMFComponentHostingController<WMFWatchlistFilterView>, WMFNavigationBarConfiguring {
    
    private let viewModel: WMFWatchlistFilterViewModel
    private weak var delegate: WMFWatchlistFilterDelegate?
    
    public init(viewModel: WMFWatchlistFilterViewModel, filterView: WMFWatchlistFilterView, delegate: WMFWatchlistFilterDelegate) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .trailing)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc private func tappedClose() {
        dismiss(animated: true)
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
