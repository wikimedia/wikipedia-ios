
class TextFormattingButton: UIButton {
    override var isSelected: Bool {
        didSet{
            self.tintColor = self.isSelected ? .black : .darkGray
        }
    }
}
