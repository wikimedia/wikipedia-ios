import Foundation
import UIKit

class WKEditorToolbarView: WKComponentView {
    
    // MARK: - Properties
    
    @IBOutlet var separatorViews: [UIView] = []
    @IBOutlet var buttons: [WKEditorToolbarButton] = []
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accessibilityElements = buttons
        updateColors()
    }
    
    // MARK: - Overrides

    override var intrinsicContentSize: CGSize {
        let height = buttons.map { $0.intrinsicContentSize.height }.max() ?? UIView.noIntrinsicMetric
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Private Helpers
    
    private func updateColors() {
        tintColor = WKAppEnvironment.current.theme.link
        backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
    }
}
