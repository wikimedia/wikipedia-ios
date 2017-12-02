import WMF

class SavedCollectionViewCell: ArticleRightAlignedImageCollectionViewCell, BatchEditableCell {
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let superSize = super.sizeThatFits(size, apply: apply)
        let isRTL = articleSemanticContentAttribute == .forceRightToLeft
        let minHeight = imageViewDimension + layoutMargins.top + layoutMargins.bottom
        var widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        
        if !isImageViewHidden {
            widthMinusMargins = widthMinusMargins - layoutMargins.right - imageViewDimension
        }
        
        var x = layoutMargins.left
        if isRTL {
            x = size.width - x - widthMinusMargins
        }
        
        let origin = CGPoint(x: x, y: layoutMargins.top)
        let height = max(origin.y, minHeight)
        
        if (apply && !isImageViewHidden) {
            let imageViewY = floor(0.5*height - 0.5*imageViewDimension)
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - imageViewDimension
            }
            imageView.frame = CGRect(x: x, y: imageViewY, width: imageViewDimension, height: imageViewDimension)
        }
        
        let separatorWidth: CGFloat = isImageViewHidden ? size.width : size.width - (imageViewDimension * 1.8)
        if (apply && !bottomSeparator.isHidden) {
            bottomSeparator.frame = CGRect(x: 0, y: height - singlePixelDimension, width: separatorWidth, height: singlePixelDimension)
        }
        
        if (apply && !topSeparator.isHidden) {
            topSeparator.frame = CGRect(x: 0, y: 0, width: separatorWidth, height: singlePixelDimension)
        }
        
        return superSize
    }
    
    var spaceForEditingControl: CGFloat = 0
    

    // MARK: - BatchEditableCell
    
    public let batchEditActionsView = BatchEditActionsView()
    
    public var batchEditActions: [BatchEditAction] {
        set {
            batchEditActionsView.actions = newValue
            updateAccessibilityElements()
        }
        get {
            return batchEditActionsView.actions
        }
    }
    
    var batchEditingState: BatchEditingState = .none {
        didSet {
            switch batchEditingState {
            case .open:
                UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.transform = CGAffineTransform(translationX: self.imageViewDimension, y: 0)
                    let newSize = CGSize(width: self.frame.width - self.imageViewDimension, height: self.frame.height)
                    self.frame.size = self.sizeThatFits(newSize, apply: true)
                    self.layoutIfNeeded()
                }, completion: nil)
            case .none:
                fallthrough
            case .cancelled:
                UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.transform = CGAffineTransform.identity
                    let oldSize = CGSize(width: self.frame.width + self.imageViewDimension, height: self.frame.height)
                    self.frame.size = self.sizeThatFits(oldSize, apply: true)
                    self.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
}
