import UIKit

@objc(WMFEditTextViewDataSource)
protocol EditTextViewDataSource: class {
    var shouldShowCustomInputViewController: Bool { get set }
}

@objc(WMFEditTextView)
class EditTextView: UITextView {
    @objc weak var dataSource: EditTextViewDataSource?

    override var inputViewController: UIInputViewController? {
        guard
            let dataSource = dataSource,
            dataSource.shouldShowCustomInputViewController else {
            return nil
        }
        return TextFormattingInputViewController.wmf_viewControllerFromStoryboardNamed("TextFormatting")
    }
}
