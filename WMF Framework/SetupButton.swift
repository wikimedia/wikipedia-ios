import UIKit

open class SetupButton: UIButton {
    
    // Subclassers should override setup instead of any of the initializers. Subclassers must call super.setup()
    open func setup() {
    }
    
    // MARK - Initializers
    // Don't override these initializers, use setup() instead
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
}
