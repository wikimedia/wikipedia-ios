import Foundation

class WKToolbarSeparatorView: WKComponentView {
    var separatorSize = CGSize(width: 1, height: 32) {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateColors()
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        return separatorSize
    }
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Private Helpers
    
    func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.border
    }
}
