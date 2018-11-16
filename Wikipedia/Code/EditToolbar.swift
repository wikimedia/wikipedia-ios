import UIKit

@objc(WMFEditToolbarDelegate)
protocol EditToolbarItemDelegate: class {
    func editToolbarDidPressBoldItem(_ editToolbar: UIToolbar, item: UIBarButtonItem)
    func editToolbarDidPressItalicItem(_ editToolbar: UIToolbar, item: UIBarButtonItem)
    func editToolbarDidPressStyleItem(_ editToolbar: UIToolbar, item: UIBarButtonItem)
    func editToolbarDidPressMoreItem(_ editToolbar: UIToolbar, item: UIBarButtonItem)
}

@objc(WMFEditToolbar)
class EditToolbar: UIToolbar {

    @objc weak var itemDelegate: EditToolbarItemDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        items = [
            UIBarButtonItem(title: "B", style: .plain, target: self, action: #selector(boldButtonPressed(_:))),
            UIBarButtonItem(title: "I", style: .plain, target: self, action: #selector(italicButtonPressed(_:))),
            UIBarButtonItem(title: "H", style: .plain, target: self, action: #selector(styleButtonPressed(_:))),
            separatorItem,
            UIBarButtonItem(title: "...", style: .plain, target: self, action: #selector(moreButtonPressed(_:)))
        ]
    }

    private lazy var separatorItem: UIBarButtonItem = {
        let separator = UIBarButtonItem(title: "|", style: .plain, target: nil, action: nil)
        separator.isEnabled = false
        return separator
    }()

    @objc private func boldButtonPressed(_ sender: UIBarButtonItem) {
        itemDelegate?.editToolbarDidPressBoldItem(self, item: sender)
    }

    @objc private func italicButtonPressed(_ sender: UIBarButtonItem) {
        itemDelegate?.editToolbarDidPressItalicItem(self, item: sender)
    }

    @objc private func styleButtonPressed(_ sender: UIBarButtonItem) {
        itemDelegate?.editToolbarDidPressStyleItem(self, item: sender)
    }

    @objc private func moreButtonPressed(_ sender: UIBarButtonItem) {
        itemDelegate?.editToolbarDidPressMoreItem(self, item: sender)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
