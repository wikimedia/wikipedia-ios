
class TextFormattingButton: UIButton {
    override var isSelected: Bool {
        didSet{
            self.tintColor = self.isSelected ? .black : .darkGray
            // self.backgroundColor = self.isSelected ? .lightGray : .clear
            // ^ once we get the updated assets from carolyn have a hangout to decide specifics for tint/bgcolor
        }
    }
}
