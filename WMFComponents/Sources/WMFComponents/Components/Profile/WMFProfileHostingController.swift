import SwiftUI

public class WMFProfileHostingController<HostedView: View>: WMFComponentHostingController<HostedView>, WMFNavigationBarConfiguring {
    
    private let viewModel: WMFProfileViewModel
    public init(rootView: HostedView, viewModel: WMFProfileViewModel) {
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
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.pageTitle, customView: nil, alignment: .leadingLarge)
        
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: viewModel.localizedStrings.doneButtonTitle, target: self, action: #selector(tappedDone), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func tappedDone() {
        dismiss(animated: true, completion: nil)
    }
}
