import SwiftUI
import UIKit

class VanishAccountCustomUIHostingController<Content: View>: UIHostingController<Content> {
    
    
    
    init(rootView: Content, title: String) {
        super.init(rootView: rootView)
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
            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIApplication.didBecomeActiveNotification)
    }
    
}
