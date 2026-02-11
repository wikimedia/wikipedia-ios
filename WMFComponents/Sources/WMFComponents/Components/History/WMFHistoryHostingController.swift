import SwiftUI

@available(iOS 16.4, *)
final public class WMFHistoryHostingController: UIHostingController<WMFHistoryView> {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
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
}
