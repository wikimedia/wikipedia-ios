class TextFormattingGroupedToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?
}

extension TextFormattingGroupedToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
