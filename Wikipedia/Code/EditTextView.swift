import UIKit

@objc(WMFEditTextViewDataSource)
protocol EditTextViewDataSource: class {
    var shouldShowCustomInputViewController: Bool { get set }
}

@objc(WMFEditTextView)
class EditTextView: UITextView {
    @objc weak var dataSource: EditTextViewDataSource?
    @objc weak var inputViewControllerDelegate: TextFormattingTableViewControllerDelegate?

    override var inputViewController: UIInputViewController? {
        guard
            let dataSource = dataSource,
            dataSource.shouldShowCustomInputViewController else {
            return nil
        }
        let textFormattingInputViewController = TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
        textFormattingInputViewController.delegate = inputViewControllerDelegate
        return textFormattingInputViewController
    }
}
