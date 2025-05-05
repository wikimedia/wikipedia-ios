import SwiftUI

public class WMFArticleTabsHostingController<HostedView: View>: WMFComponentHostingController<HostedView>, WMFNavigationBarConfiguring {
    
    private let viewModel: WMFArticleTabsViewModel
    public init(rootView: HostedView, viewModel: WMFArticleTabsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: rootView)
    }
    
    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "x tabs", customView: nil, alignment: .centerCompact)
        
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: "Done", target: self, action: #selector(tappedDone), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func tappedDone() {
        dismiss(animated: true, completion: nil)
    }
}
