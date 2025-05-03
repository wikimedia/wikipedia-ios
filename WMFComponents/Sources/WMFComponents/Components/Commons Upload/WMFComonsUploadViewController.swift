import UIKit
import SwiftUI

fileprivate final class WMFComonsUploadHostingController: WMFComponentHostingController<WWMFCommonsUploadView> {

}

final public class WMFComonsUploadViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    private let hostingViewController: WMFComonsUploadHostingController
    private let viewModel: WMFCommonsUploadViewModel

    public init(viewModel: WMFCommonsUploadViewModel) {
        self.viewModel = viewModel
        let view = WWMFCommonsUploadView(viewModel: viewModel)
        self.hostingViewController = WMFComonsUploadHostingController(rootView: view)
        super.init()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "Media details", customView: nil, alignment: .centerCompact)
        let trailingButtonConfig = WMFNavigationBarCloseButtonConfig(text: "Upload", target: self, action: #selector(tappedUpload), alignment: .trailing)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: trailingButtonConfig, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func tappedUpload() {
        print("Upload")
    }

}
