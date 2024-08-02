import UIKit

public protocol WMFAltTextExperimentModalSheetDelegate: AnyObject {
    func didTapNext(altText: String)
}

final public class WMFAltTextExperimentModalSheetViewController: WKCanvasViewController {

    weak var viewModel: WMFAltTextExperimentModalSheetViewModel?
    weak var delegate: WMFAltTextExperimentModalSheetDelegate?

    public init(viewModel: WMFAltTextExperimentModalSheetViewModel?, delegate: WMFAltTextExperimentModalSheetDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel else { return }
        let view = WMFAltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel, delegate: delegate)
        addComponent(view, pinToEdges: true)
    }

}

