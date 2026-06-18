import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFNativeLocalizations

public final class WMFWhichCameFirstArchiveViewController: UIViewController, WMFNavigationBarConfiguring {

    private let viewModel: WMFWhichCameFirstArchiveViewModel

    public init(viewModel: WMFWhichCameFirstArchiveViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.onShowScoreToast = { message in
            WMFToastManager.sharedInstance.showToast(message, sticky: false, dismissPreviousToasts: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let archiveView = WMFWhichCameFirstArchiveView(viewModel: viewModel)
        let hostingVC = UIHostingController(rootView: archiveView)
        addChild(hostingVC)
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingVC.didMove(toParent: self)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .centerCompact)
        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(didTapClose),
            alignment: .leading
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}
