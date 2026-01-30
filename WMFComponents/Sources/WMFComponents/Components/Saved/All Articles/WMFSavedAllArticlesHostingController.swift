import UIKit
import SwiftUI

public final class WMFSavedAllArticlesHostingController: WMFComponentHostingController<WMFSavedAllArticlesView> {
    
    public let viewModel: WMFSavedAllArticlesViewModel
    
    public init(viewModel: WMFSavedAllArticlesViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFSavedAllArticlesView(viewModel: viewModel))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }
    
    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }
}
