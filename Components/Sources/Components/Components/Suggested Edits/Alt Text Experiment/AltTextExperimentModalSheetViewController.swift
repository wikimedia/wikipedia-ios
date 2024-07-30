import UIKit

final class AltTextExperimentModalSheetViewController: WKCanvasViewController {

    weak var viewModel: AltTextExperimentModalSheetViewModel?


    init(viewModel: AltTextExperimentModalSheetViewModel? = nil) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel else { return }
        let view = AltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel)
        addComponent(view, pinToEdges: true)
    }

}
