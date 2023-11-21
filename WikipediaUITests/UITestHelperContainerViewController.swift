import UIKit
import WMF
import SwiftUI

class UITestHelperViewController: UIViewController {
    
    private let hostingController: UITestHelperContainerViewController
    private let theme: Theme

    init(theme: Theme) {
        self.hostingController = UITestHelperContentView<UITestHelperContentView>()
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UITestHelperContainerViewController: UIHostingController<UITestHelperContentView> {

}

struct UITestHelperContentView: View {
    
    var body: some View {
        Text("View")
    }
}

