protocol TextFormattingToolbarViewDelegate: class {

}

class TextFormattingToolbarView: UIView {
    weak var delegate: TextFormattingToolbarViewDelegate?
}

extension TextFormattingToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
