import UIKit

public protocol AltTextExperimentModalSheetDelegate: AnyObject {
    func didTapNext(altText: String)
}

final public class AltTextExperimentModalSheetViewController: WKCanvasViewController {

    weak var viewModel: AltTextExperimentModalSheetViewModel?
    weak var delegate: AltTextExperimentModalSheetDelegate?

    public init(viewModel: AltTextExperimentModalSheetViewModel?, delegate: AltTextExperimentModalSheetDelegate?) {
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
        let view = AltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel, delegate: delegate)
        addComponent(view, pinToEdges: true)
    }

}

