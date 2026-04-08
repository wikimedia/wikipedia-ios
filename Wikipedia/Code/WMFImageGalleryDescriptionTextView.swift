@objcMembers class WMFImageGalleryDescriptionTextView: UITextView {
    public var availableHeight: CGFloat = 0 {
        didSet {
            if oldValue != availableHeight {
                invalidateIntrinsicContentSize()
            }
        }
    }

    private let minHeight = 30

    override func awakeFromNib() {
        super.awakeFromNib()
        registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) { [weak self] (textView: Self, previousTraitCollection: UITraitCollection) in
            guard let self else { return }
            self.setContentOffset(.zero, animated: false)
            self.invalidateIntrinsicContentSize() // Needed so height is correctly adjusted on rotation.
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        // Size to fit all text content. When availableHeight is known, cap at that value
        // so the caption never exceeds the screen. The text view is scrollable for overflow.
        // When availableHeight is 0 (not yet set), return the uncapped natural height so
        // auto layout doesn't collapse the view before the first real layout pass.
        if availableHeight > 0 {
            size.height = fmax(CGFloat(minHeight), fmin(size.height, availableHeight))
        } else {
            size.height = fmax(CGFloat(minHeight), size.height)
        }
        return size
    }

    override func invalidateIntrinsicContentSize() {
        isScrollEnabled = false // UITextView intrinsicContentSize only works when scrolling is false
        super.invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isScrollEnabled = true
    }
}
