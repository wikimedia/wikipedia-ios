import SwiftUI

public class WMFTabsHostingController: WMFComponentHostingController<WMFTabsView>, WMFNavigationBarConfiguring {

    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var viewModel: WMFTabsViewModel
    
    public init(viewModel: WMFTabsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFTabsView(viewModel: viewModel))
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .hidden)
        
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: "Done", target: self, action: #selector(tappedDone), alignment: .leading)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .plus), style: .plain, target: self, action: #selector(tappedAdd))
    }
    
    @objc func tappedDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func tappedAdd() {
        viewModel.tappedAddTabAction?()
    }
}
