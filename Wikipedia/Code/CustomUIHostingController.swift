import UIKit
import SwiftUI
import WMF

extension Notification.Name {
     static let swiftUITextfieldDidBeginEditing = Notification.Name("swiftUITextfieldDidBeginEditing")
     static let swiftUITextfieldDidEndEditing = Notification.Name("swiftUITextfieldDidEndEditing")
}


/// Conform SwiftUI view to this and embed in a CustomUIHostingController. It will respond to swiftUITextfieldDidBeginEditing and swiftUITextfieldDidEndEditing calls and add a Done button in the navigation bar for keyboard dismissal.
protocol NavBarKeyboardDismissable {
    
}

class CustomUIHostingController<Content: View>: UIHostingController<Content> {
    
    private lazy var doneButton = UIBarButtonItem(title: CommonStrings.doneTitle, style: .done, target: self, action: #selector(tappedDone))
    
    init(rootView: Content, title: String) {
        super.init(rootView: rootView)
        self.title = title
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if rootView is NavBarKeyboardDismissable {
            NotificationCenter.default.addObserver(self, selector: #selector(textfieldDidBeginEditing), name: .swiftUITextfieldDidBeginEditing, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(textfieldDidEndEditing), name: .swiftUITextfieldDidEndEditing, object: nil)
        }
    }
    
    @objc func textfieldDidBeginEditing() {
        navigationItem.rightBarButtonItem = doneButton
    }

    @objc func textfieldDidEndEditing() {
        navigationItem.rightBarButtonItem = nil
    }

    @objc func tappedDone() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
