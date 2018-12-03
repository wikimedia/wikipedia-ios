protocol TextFormattingGroupedToolbarViewDelegate: class {

}

class TextFormattingGroupedToolbarView: UIView {
    weak var delegate: TextFormattingGroupedToolbarViewDelegate?
}

extension TextFormattingGroupedToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
