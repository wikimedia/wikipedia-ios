import SwiftUI

final public class WMFHistoryHostingController: WMFComponentHostingController<WMFHistoryView> {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        disableContentInsetAdjustments()
        view.backgroundColor = WMFAppEnvironment.current.theme.paperBackground
    }
    
    // Helps to fix weird spacing at the top when Search is unfocused
    public func disableContentInsetAdjustments() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let scrollView = findScrollView(in: self.view) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }
    }
    
    // Disable automatic content inset adjustment
    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews {
            if let found = findScrollView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    public override func appEnvironmentDidChange() {
        view.backgroundColor = theme.paperBackground
    }
}
