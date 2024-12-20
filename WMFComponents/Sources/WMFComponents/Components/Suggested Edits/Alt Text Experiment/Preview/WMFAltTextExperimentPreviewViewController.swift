import UIKit
import WMFComponents

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

final public class WMFAltTextExperimentPreviewViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

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
 
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
        
        publishButton = UIBarButtonItem(title: viewModel.localizedStrings.publishTitle, style: .done, target: self, action: #selector(publishWikitext))
        navigationItem.rightBarButtonItem = publishButton
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

}
