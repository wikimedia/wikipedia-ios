protocol MediaWizardControllerDelegate: AnyObject {
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didPrepareViewController viewController: UIViewController)
    func mediaWizardController(_ mediaWizardController: MediaWizardController, didTapCloseButton button: UIBarButtonItem)
}

final class MediaWizardController {
    weak var delegate: MediaWizardControllerDelegate?

    func prepare(with theme: Theme) {
        let topViewController = InsertMediaImageViewController(nibName: "InsertMediaImageViewController", bundle: nil)
        let tabbedViewController = TabbedViewController(viewControllers: [InsertMediaSearchCollectionViewController(), UploadMediaViewController()])
        let bottomViewController = WMFThemeableNavigationController(rootViewController: tabbedViewController)
        bottomViewController.isNavigationBarHidden = true
        let verticallySplitViewController = VerticallySplitViewController(topViewController: topViewController, bottomViewController: bottomViewController)
        verticallySplitViewController.navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(delegateCloseButtonTap(_:)))
        verticallySplitViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .plain, target: self, action: #selector(goToMediaSettings))
        verticallySplitViewController.title = WMFLocalizedString("insert-media-title", value: "Insert media", comment: "Title for the view in charge of inserting media into an article")
        let navigationController = WMFThemeableNavigationController(rootViewController: verticallySplitViewController, theme: theme)
        delegate?.mediaWizardController(self, didPrepareViewController: navigationController)
    }

    @objc private func delegateCloseButtonTap(_ sender: UIBarButtonItem) {
        delegate?.mediaWizardController(self, didTapCloseButton: sender)
    }

    @objc private func goToMediaSettings(_ sender: UIBarButtonItem) {

    }
}
