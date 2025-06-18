import SwiftUI

final class TalkPageTopicReplyOnboardingHostingController: UIHostingController<TalkPageTopicReplyOnboardingView>, UIAdaptivePresentationControllerDelegate, Themeable, RMessageSuppressing {

    // MARK: - Properties
    let dismissAction: () -> Void
    var theme: Theme

    // MARK: - Lifecycle

    init(dismissAction: @escaping () -> Void, theme: Theme) {
        self.theme = theme
        self.dismissAction = dismissAction
        super.init(rootView: TalkPageTopicReplyOnboardingView(theme: theme))
        rootView.dismissAction = { [weak self] in
            self?.dismiss()
        }
        view.backgroundColor = theme.colors.paperBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentationController?.delegate = self
    }

    // MARK: - Actions

    fileprivate func dismiss() {
        dismiss(animated: true, completion: { [weak self] in
            self?.dismissAction()
        })
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissAction()
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        self.rootView.theme = theme
        view.backgroundColor = theme.colors.paperBackground
    }

}
