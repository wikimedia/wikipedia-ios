import UIKit
import SwiftUI
import WMFComponents

class NotificationsCenterModalHostingController<Content>: UIHostingController<Content> where Content: View {
    
    private let customTitle: String
    
    init(rootView: Content, title: String) {
        self.customTitle = title
        super.init(rootView: rootView)
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleConfig = WMFNavigationBarTitleConfig(title: customTitle, customView: nil, alignment: .centerCompact, customLargeTitleFont: nil)
        let closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(tappedClose), alignment: .trailing)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func tappedClose() {
        dismiss(animated: true)
    }
}

extension NotificationsCenterModalHostingController: NotificationsCenterFlowViewController {
    func tappedPushNotification() {
        dismiss(animated: true, completion: nil)
    }
}

extension NotificationsCenterModalHostingController: WMFNavigationBarConfiguring {
    
}
