import SwiftUI
import UIKit

class VanishAccountCustomUIHostingController: UIHostingController<VanishAccountContentView> {
    
    var shouldShowPopUp = false
    var userInput = String()
    
    init(title: String, theme: Theme, username: String) {
        super.init(rootView: VanishAccountContentView(theme: theme, username: username))
        rootView.userInput = userInput
        self.title = title
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIApplication.didBecomeActiveNotification)
    }
    
}
