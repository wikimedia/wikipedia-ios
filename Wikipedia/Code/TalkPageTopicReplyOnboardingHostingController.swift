import SwiftUI

protocol TalkPageTopicReplyOnboardingDelegate: AnyObject {
    func userDidDismissTopicReplyOnboardingView()
}

final class TalkPageTopicReplyOnboardingHostingController: UIHostingController<TalkPageTopicReplyOnboardingView>, UIAdaptivePresentationControllerDelegate, Themeable, RMessageSuppressing {

    // MARK: - Properties

    weak var delegate: TalkPageTopicReplyOnboardingDelegate?
    var theme: Theme

    // MARK: - Lifecycle

    init(theme: Theme) {
        self.theme = theme
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
        dismiss(animated: true, completion: {
            self.delegate?.userDidDismissTopicReplyOnboardingView()
        })
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.userDidDismissTopicReplyOnboardingView()
        
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        self.rootView.theme = theme
        view.backgroundColor = theme.colors.paperBackground
    }

}
