class TextFormattingGroupedToolbarView: TextFormattingToolbarView {
    
    @IBOutlet var separators: [UIView]!
    
    @IBAction private func increaseIndent(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapIncreaseIndent()
    }
    @IBAction private func decreaseIndent(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapDecreaseIndent()
    }
    @IBAction private func toggleUnorderedList(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapUnorderedList()
    }
    @IBAction private func toggleOrderedList(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapOrderedList()
    }
    @IBAction private func toggleSuperscript(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapSuperscript()
    }
    @IBAction private func toggleSubscript(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapSubscript()
    }
    @IBAction private func toggleUnderline(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapUnderline()
    }
    @IBAction private func toggleStrikethrough(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapStrikethrough()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        for separator in separators {
            separator.backgroundColor = theme.colors.border
        }
    }
}
