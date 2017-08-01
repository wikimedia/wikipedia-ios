import UIKit

class ImageDimmingExampleViewController: UIViewController {
    
    fileprivate var theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: self.theme)
    }
    
}

extension ImageDimmingExampleViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.baseBackground
        view.alpha = theme.imageOpacity
    }
}
