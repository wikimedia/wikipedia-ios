import Foundation
import SwiftUI

protocol VanishAccountWarningViewDelegate: AnyObject {
    func userDidDismissVanishAccountWarningView(presentVanishView: Bool)
}

final class VanishAccountWarningViewHostingViewController: UIHostingController<VanishAccountWarningView>, UIAdaptivePresentationControllerDelegate, Themeable, RMessageSuppressing {

    // MARK: - Properties

    weak var delegate: VanishAccountWarningViewDelegate?
    var theme: Theme

    // MARK: - Lifecycle

    init(theme: Theme) {
        self.theme = theme
        super.init(rootView: VanishAccountWarningView(theme: theme))

        rootView.dismissAction = { [weak self] in
            self?.dismiss(userTappedContinue: false)
        }
        rootView.continueAction = { [weak self] in
            self?.dismiss(userTappedContinue: true)
        }

        view.backgroundColor = theme.colors.paperBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentationController?.delegate = self
    }

    // MARK: - Actions

    fileprivate func dismiss(userTappedContinue: Bool) {
        dismiss(animated: true, completion: {
            self.delegate?.userDidDismissVanishAccountWarningView(presentVanishView: userTappedContinue)
        })
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.userDidDismissVanishAccountWarningView(presentVanishView: false)
    }

    // MARK: - Themeable

    func apply(theme: Theme) {
        self.theme = theme
        self.rootView.theme = theme
        view.backgroundColor = theme.colors.paperBackground
    }

}
