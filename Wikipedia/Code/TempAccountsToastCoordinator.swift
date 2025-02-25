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
    var title: String
    var readMoreButtonTitle: String
    
    public init(navigationController: UINavigationController, didTapReadMore: @escaping () -> Void, didTapClose: @escaping () -> Void, toastController: WMFTempAccountsToastHostingController? = nil, title: String, readMoreButtonTitle: String) {
        self.navigationController = navigationController
        self.didTapReadMore = didTapReadMore
        self.didTapClose = didTapClose
        self.toastController = toastController
        self.title = title
        self.readMoreButtonTitle = readMoreButtonTitle
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
                self?.didTapClose()
                self?.removeToast()
            },
            title: title,
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
            toastController.view.topAnchor.constraint(equalTo: topViewController.view.safeAreaLayoutGuide.topAnchor, constant: 8),
            toastController.view.widthAnchor.constraint(lessThanOrEqualToConstant: 350)
        ])

        toastController.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            toastController.view.alpha = 1
        }

        self.toastController = toastController
    }
    
    private func removeToast() {
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
