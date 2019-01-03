protocol TextFormattingProviding: class {
    var delegate: TextFormattingDelegate? { get set }
}

protocol TextFormattingDelegate: class {
    func textFormattingProvidingDidTapClose()
    func textFormattingProvidingDidTapHeading(depth: Int)
    func textFormattingProvidingDidTapBold()
    func textFormattingProvidingDidTapItalics()
    func textFormattingProvidingDidTapUnderline()
    func textFormattingProvidingDidTapStrikethrough()
    func textFormattingProvidingDidTapReference()
    func textFormattingProvidingDidTapTemplate()
    func textFormattingProvidingDidTapComment()
    func textFormattingProvidingDidTapLink()
    func textFormattingProvidingDidTapIncreaseIndent()
    func textFormattingProvidingDidTapDecreaseIndent()
    func textFormattingProvidingDidTapOrderedList()
    func textFormattingProvidingDidTapUnorderedList()
    func textFormattingProvidingDidTapSuperscript()
    func textFormattingProvidingDidTapSubscript()

    func textFormattingProvidingDidTapTextFormatting()
    func textFormattingProvidingDidTapTextStyleFormatting()
}
