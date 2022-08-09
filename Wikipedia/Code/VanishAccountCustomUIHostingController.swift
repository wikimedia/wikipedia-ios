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
    
    
}
