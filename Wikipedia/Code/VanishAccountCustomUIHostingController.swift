import SwiftUI
import UIKit

class VanishAccountCustomUIHostingController: UIHostingController<VanishAccountContentView> {
    
    var shouldShowPopUp = false
    
    init(title: String, theme: Theme, username: String) {
        super.init(rootView: VanishAccountContentView(theme: theme, username: username))
        rootView.showPopUp = false

        
        self.title = title
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldShowModal), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        
    }
    
    @objc func shouldShowModal() {
        let userDefaults = UserDefaults.standard
        if userDefaults.wmf_shouldShowVanishingRequestModal {
            shouldShowPopUp = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIApplication.didBecomeActiveNotification)
    }
    
}
