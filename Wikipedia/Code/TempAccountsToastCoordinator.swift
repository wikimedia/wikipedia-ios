import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@objc(TempAccountsToastCoordinator)
final class TempAccountsToastCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController
    var didTapReadMore: () -> Void
    var didTapClose: () -> Void
    var toastController: WMFTempAccountsToastHostingController? = nil
    var readMoreButtonTitle: String
    
    var fullPageInformation = {
        let openingLinkLogIn = "<a href=\"\">"
        let openingLinkCreateAccount = "<a href=\"\">"
        let openingLinkOtherFeatures = "<a href=\"\">"
        let closingLink = "</a>"
        let openingBold = "<b>"
        let closingBold = "</b>"
        let lineBreaks = "<br/><br/>"
        let username = "abc"
        let format = WMFLocalizedString("temp-account-toast-full-information", value: "%1$@You are using a temporary account.%2$@ Edits are being attributed to %1$@%3$@.%2$@%4$@ %5$@Log in%6$@ or %7$@create an account%6$@ to get credit for future edits, and access %8$@other features%6$@.",
          comment: "Temporary accounts toast information. $1 and $2 are opening and closing bold, $3 is the temporary username, $4 is linebreaks, $5 is the opening link for logging in, $6 is closing link, $7 is the opening link for creating an account, and $8 is the opening link for other features.")
        return String.localizedStringWithFormat(format, openingBold, closingBold, username, lineBreaks, openingLinkLogIn, closingLink, openingLinkCreateAccount, openingLinkOtherFeatures)
    }
    
    var title = {
        let openingBold = "<b>"
        let closingBold = "</b>"
        let format = WMFLocalizedString("temp-account-toast-title", value: "%1$@You are currently using a temporary account.%2$@ Edits made with the temporary...",
          comment: "Temporary accounts toast information. $1 and $2 are opening and closing bold")
        return String.localizedStringWithFormat(format, openingBold, closingBold)
    }
    
    public init(navigationController: UINavigationController, didTapReadMore: @escaping () -> Void, didTapClose: @escaping () -> Void, toastController: WMFTempAccountsToastHostingController? = nil) {
        self.navigationController = navigationController
        self.didTapReadMore = didTapReadMore
        self.didTapClose = didTapClose
        self.toastController = toastController
        readMoreButtonTitle = "Read more"
    }
    
    func start() {
        presentToast()
    }
    
    private func presentToast() {
        let viewModel = WMFTempAccountsToastViewModel(
            didTapReadMore: { [weak self] in
                self?.didTapReadMore()
            },
            didTapClose: { [weak self] in
                self?.dismissToast()
            },
            title: title(),
            readMoreButtonTitle: readMoreButtonTitle
        )

        toastController = WMFTempAccountsToastHostingController(viewModel: viewModel)

        guard let topViewController = navigationController.viewControllers.last else { return }
        guard let toastController else { return }

        topViewController.addChild(toastController)
        topViewController.view.addSubview(toastController.view)
        toastController.didMove(toParent: topViewController)

        toastController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toastController.view.centerXAnchor.constraint(equalTo: topViewController.view.centerXAnchor),
            toastController.view.topAnchor.constraint(equalTo: topViewController.view.safeAreaLayoutGuide.topAnchor),
            toastController.view.leadingAnchor.constraint(equalTo: topViewController.view.leadingAnchor),
            toastController.view.trailingAnchor.constraint(equalTo: topViewController.view.trailingAnchor)
        ])

        toastController.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toastController.view.alpha = 1
        }

        self.toastController = toastController
    }
    
    public func dismissToast() {
        guard let toastController = self.toastController else { return }

        UIView.animate(withDuration: 0.3, animations: {
            toastController.view.alpha = 0
        }) { _ in
            toastController.willMove(toParent: nil)
            toastController.view.removeFromSuperview()
            toastController.removeFromParent()
            self.toastController = nil
        }
    }

}
