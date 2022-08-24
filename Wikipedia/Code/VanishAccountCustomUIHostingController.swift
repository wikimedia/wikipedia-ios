import SwiftUI
import UIKit
import WMF

class VanishAccountCustomUIHostingController: UIHostingController<VanishAccountContentView> {
    
    init(title: String, theme: Theme, username: String) {
        super.init(rootView: VanishAccountContentView(theme: theme, username: username))
        self.title = title
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
