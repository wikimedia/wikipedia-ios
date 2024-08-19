import UIKit

public protocol WMFAltTextExperimentModalSheetDelegate: AnyObject {
   func didTapNext(altText: String)
}

public protocol WMFAltTextExperimentModalSheetLoggingDelegate: AnyObject {
    func didAppear()
    func didFocusTextView()
    func didTriggerCharacterWarning()
    func didTapFileName()
}

final public class WMFAltTextExperimentModalSheetViewController: WMFCanvasViewController {

    weak var viewModel: WMFAltTextExperimentModalSheetViewModel?
    weak var delegate: WMFAltTextExperimentModalSheetDelegate?
    weak var loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?

    public init(viewModel: WMFAltTextExperimentModalSheetViewModel?, delegate: WMFAltTextExperimentModalSheetDelegate?, loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.loggingDelegate = loggingDelegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel else { return }
        let view = WMFAltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
        addComponent(view, pinToEdges: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loggingDelegate?.didAppear()
    }
}

