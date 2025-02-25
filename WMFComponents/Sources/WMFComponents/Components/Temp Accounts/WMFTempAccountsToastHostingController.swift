import SwiftUI

public class WMFTempAccountsToastHostingController: UIHostingController<WMFTempAccountsToastView> {
    var viewModel: WMFTempAccountsToastViewModel
    var toastViewController: WMFTempAccountsToastHostingController?

    public init(viewModel: WMFTempAccountsToastViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFTempAccountsToastView(viewModel: viewModel))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(viewModel:) instead.")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    func showToast(viewModel: WMFTempAccountsToastViewModel) {
        removeToast()

        let toastVC = WMFTempAccountsToastHostingController(viewModel: viewModel)
        toastVC.view.translatesAutoresizingMaskIntoConstraints = false
        toastVC.view.alpha = 0

        addChild(toastVC)
        view.addSubview(toastVC.view)
        toastVC.didMove(toParent: self)

        NSLayoutConstraint.activate([
            toastVC.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            toastVC.view.widthAnchor.constraint(lessThanOrEqualToConstant: 350)
        ])

        toastViewController = toastVC

        UIView.animate(withDuration: 0.3) {
            toastVC.view.alpha = 1
        }
    }

    func removeToast() {
        guard let toastVC = toastViewController else { return }

        UIView.animate(withDuration: 0.3, animations: {
            toastVC.view.alpha = 0
        }) { _ in
            toastVC.willMove(toParent: nil)
            toastVC.view.removeFromSuperview()
            toastVC.removeFromParent()
            self.toastViewController = nil
        }
    }
}
