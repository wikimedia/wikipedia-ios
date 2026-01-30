import UIKit
import SwiftUI

public final class WMFAllArticlesHostingController: WMFComponentHostingController<WMFAllArticlesView> {
    
    public let viewModel: WMFAllArticlesViewModel
    
    public init(viewModel: WMFAllArticlesViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFAllArticlesView(viewModel: viewModel))
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
