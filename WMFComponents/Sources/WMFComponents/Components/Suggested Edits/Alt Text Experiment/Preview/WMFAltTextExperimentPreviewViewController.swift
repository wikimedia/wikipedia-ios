import UIKit

public protocol WMFAltTextPreviewDelegate: AnyObject {
    func didTapPublish(viewModel: WMFAltTextExperimentPreviewViewModel)
}

final fileprivate class WMFAltTextExperimentPreviewHostingViewController: WMFComponentHostingController<WMFAltTextExperimentPreviewView> {

    init(viewModel: WMFAltTextExperimentPreviewViewModel) {
        let rootView = WMFAltTextExperimentPreviewView(viewModel: viewModel)
        super.init(rootView: rootView)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final public class WMFAltTextExperimentPreviewViewController: WMFCanvasViewController {

    // MARK: Properties

    private let hostingViewController: WMFAltTextExperimentPreviewHostingViewController
    private var viewModel: WMFAltTextExperimentPreviewViewModel
    private var publishButton: UIBarButtonItem?
    public weak var delegate: WMFAltTextPreviewDelegate?

    // MARK: Lifecycle

    public init(viewModel: WMFAltTextExperimentPreviewViewModel, delegate: WMFAltTextPreviewDelegate?) {
        self.hostingViewController = WMFAltTextExperimentPreviewHostingViewController(viewModel: viewModel)
        self.delegate = delegate
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.localizedStrings.title
        navigationItem.backButtonDisplayMode = .generic
        let image = WMFSFSymbolIcon.for(symbol: .chevronBackward, font: .boldCallout)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(tappedBack))
        publishButton = UIBarButtonItem(title: viewModel.localizedStrings.publishTitle, style: .done, target: self, action: #selector(publishWikitext))
        navigationItem.rightBarButtonItem = publishButton
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: Public Methods

    public func updatePublishButtonState(isEnabled: Bool) {
        publishButton?.isEnabled = isEnabled
    }

    // MARK: Private Methods

    @objc private func publishWikitext() {
        self.delegate?.didTapPublish(viewModel: self.viewModel)
        updatePublishButtonState(isEnabled: false)
    }

    @objc private func tappedBack() {
        navigationController?.popViewController(animated: true)
    }

}
