import UIKit

public protocol AltTextExperimentModalSheetDelegate: AnyObject {
    func didTapNext(altText: String)
}

public protocol AltTextExperimentModalSheetLoggingDelegate: AnyObject {
    func didAppear()
    func didFocusTextView()
}

final public class AltTextExperimentModalSheetViewController: WKCanvasViewController {

    weak var viewModel: AltTextExperimentModalSheetViewModel?
    weak var delegate: AltTextExperimentModalSheetDelegate?
    weak var loggingDelegate: AltTextExperimentModalSheetLoggingDelegate?

    public init(viewModel: AltTextExperimentModalSheetViewModel?, delegate: AltTextExperimentModalSheetDelegate?, loggingDelegate: AltTextExperimentModalSheetLoggingDelegate?) {
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
        let view = AltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
        addComponent(view, pinToEdges: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loggingDelegate?.didAppear()
    }
}

