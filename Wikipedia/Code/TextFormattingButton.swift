
class TextFormattingButton: UIButton {
    override var isSelected: Bool {
        didSet{
            self.tintColor = self.isSelected ? .black : .darkGray
            self.backgroundColor = self.isSelected ? .lightGray : .clear
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    override open var intrinsicContentSize: CGSize {
        get {
            // Increase touch targets & make widths more consistent
            let superSize = super.intrinsicContentSize
            return CGSize(width: max(superSize.width, 35), height: superSize.height)
        }
    }
}
