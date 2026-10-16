import SwiftUI

@MainActor
public protocol WMFSlideshowViewDelegate: AnyObject {
    func slideshowViewDidTapPrimaryButton()
    func slideshowViewDidTapSecondaryButton()
    func slideshowViewDidTapCloseButton()
}

/// Present inside a `WMFComponentNavigationController`, which this configures on appearance.
public final class WMFSlideshowViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    public weak var delegate: WMFSlideshowViewDelegate? {
        didSet {
            hostingController.delegate = delegate
        }
    }

    public let hostingController: WMFSlideshowHostingViewController

    private let viewModel: WMFSlideshowViewModel

    public init(viewModel: WMFSlideshowViewModel) {
        self.viewModel = viewModel
        self.hostingController = WMFSlideshowHostingViewController(viewModel: viewModel)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .hidden)

        var closeButtonConfig: WMFLargeCloseButtonConfig?
        if viewModel.showsCloseButton {
            closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)

        if let closeButtonAccessibilityLabel = viewModel.localizedStrings.closeButtonAccessibilityLabel {
            navigationItem.leftBarButtonItem?.accessibilityLabel = closeButtonAccessibilityLabel
        }
    }

    @objc private func tappedClose() {
        if let closeAction = viewModel.closeAction {
            closeAction()
        } else {
            delegate?.slideshowViewDidTapCloseButton()
        }
    }
}

public final class WMFSlideshowHostingViewController: WMFComponentHostingController<WMFSlideshowView> {

    public weak var delegate: WMFSlideshowViewDelegate?

    init(viewModel: WMFSlideshowViewModel) {
        super.init(rootView: WMFSlideshowView(viewModel: viewModel))

        self.rootView.primaryAction = { [weak self] in
            self?.delegate?.slideshowViewDidTapPrimaryButton()
        }

        self.rootView.secondaryAction = { [weak self] in
            self?.delegate?.slideshowViewDidTapSecondaryButton()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
