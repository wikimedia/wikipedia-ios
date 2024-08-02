import Foundation
import UIKit

class WMFEditorToolbarView: WMFComponentView {
    
    // MARK: - Properties
    
    @IBOutlet var separatorImageViews: [UIImageView] = []
    @IBOutlet var separatorImageWidthConstraints: [NSLayoutConstraint] = []
    @IBOutlet var buttons: [WMFEditorToolbarButton] = []
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accessibilityElements = buttons
        
        let width = (1.0 / UIScreen.main.scale) * 2
        for separatorImageView in self.separatorImageViews {
            
            let image = UIImage.roundedRectImage(with: .black, cornerRadius: 0, width: width, height: 32)
            separatorImageView.image = image?.withRenderingMode(.alwaysTemplate)
        }
        
        for separatorWidthConstraint in separatorImageWidthConstraints {
            separatorWidthConstraint.constant = width
        }
        
        updateColors()
        maximumContentSizeCategory = .accessibilityMedium
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
        backgroundColor = WMFAppEnvironment.current.theme.paperBackground
        
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
        layer.shadowColor = theme.editorKeyboardShadow.cgColor
        
        for separatorImageView in separatorImageViews {
            separatorImageView.tintColor = theme.newBorder
        }
    }
}
