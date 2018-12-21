
class TextFormattingButton: UIButton {
    override var isSelected: Bool {
        didSet{
            self.tintColor = self.isSelected ? .black : .darkGray
            // self.backgroundColor = self.isSelected ? .lightGray : .clear
            // ^ once we get the updated assets from carolyn have a hangout to decide specifics for tint/bgcolor
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        get {
            // Workaround for increasing touch targets
            let superSize = super.intrinsicContentSize
            return CGSize(width: max(superSize.width, 35), height: superSize.height)
        }
    }
}
