import SwiftUI

protocol NotificationsCenterOnboardingDelegate: AnyObject {
    func userDidDismissNotificationsCenterOnboardingView()
}

final class NotificationsCenterOnboardingHostingViewController: UIHostingController<NotificationsCenterOnboardingView>, UIAdaptivePresentationControllerDelegate, Themeable, RMessageSuppressing {

    // MARK: - Properties

    weak var delegate: NotificationsCenterOnboardingDelegate?
    var theme: Theme

    // MARK: - Lifecycle

    init(theme: Theme) {
        self.theme = theme
        super.init(rootView: NotificationsCenterOnboardingView(theme: theme))
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
        dismiss(animated: true, completion: {
            self.delegate?.userDidDismissNotificationsCenterOnboardingView()
        })
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.userDidDismissNotificationsCenterOnboardingView()
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        self.rootView.theme = theme
        view.backgroundColor = theme.colors.paperBackground
    }

}
