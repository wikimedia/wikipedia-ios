import UIKit

protocol EditNoticesViewControllerDelegate: AnyObject {
    func editNoticesControllerUserTapped(url: URL)
}

class EditNoticesViewController: ThemeableViewController, RMessageSuppressing {

    // MARK: - Properties

    let viewModel: EditNoticesViewModel

    weak var delegate: EditNoticesViewControllerDelegate?

    var editNoticesView: EditNoticesView {
        return view as! EditNoticesView
    }

    // MARK: - Lifecycle

    init(theme: Theme, viewModel: EditNoticesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let editNoticesView = EditNoticesView(frame: UIScreen.main.bounds)
        view = editNoticesView
        editNoticesView.configure(viewModel: viewModel, theme: theme)

        editNoticesView.doneButton.addTarget(self, action: #selector(dismissView), for: .primaryActionTriggered)
        editNoticesView.toggleSwitch.addTarget(self, action: #selector(didToggleSwitch(_:)), for: .valueChanged)
        editNoticesView.toggleSwitch.isOn = UserDefaults.standard.wmf_alwaysDisplayEditNotices
        editNoticesView.textView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIAccessibility.post(notification: .screenChanged, argument: editNoticesView.editNoticesTitle)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.editNoticesView.changeTextViewVoiceOverVisibility(isVisible: true)
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    // MARK: - Actions

    @objc private func dismissView() {
        dismiss(animated: true)
    }

    @objc private func didToggleSwitch(_ sender: UISwitch) {
        UserDefaults.standard.wmf_alwaysDisplayEditNotices = sender.isOn
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        editNoticesView.configure(viewModel: viewModel, theme: theme)
    }

}

extension EditNoticesViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let url = URL(string: url.absoluteString, relativeTo: viewModel.siteURL) else {
             return false
        }

        dismiss(animated: true) {
            self.delegate?.editNoticesControllerUserTapped(url: url)
        }

        return false
    }

}
