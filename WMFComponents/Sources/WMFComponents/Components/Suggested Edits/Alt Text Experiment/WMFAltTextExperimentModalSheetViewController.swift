import UIKit

public protocol WMFAltTextExperimentModalSheetDelegate: AnyObject {
    func didTapNext(altText: String)
    func didTapImage(fileName: String)
    func didTapFileName(fileName: String)
    func didTapGuidance()
}

public protocol WMFAltTextExperimentModalSheetLoggingDelegate: AnyObject {
    func didAppear()
    func didFocusTextView()
    func didTriggerCharacterWarning()
    func didTapFileName()
}

final public class WMFAltTextExperimentModalSheetViewController: WMFCanvasViewController {

    weak var viewModel: WMFAltTextExperimentModalSheetViewModel?
    public var tooltipViewModels: [WMFTooltipViewModel] = []
    weak var delegate: WMFAltTextExperimentModalSheetDelegate?
    weak var loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?
    weak var modalSheetView: WMFAltTextExperimentModalSheetView?

    public init(viewModel: WMFAltTextExperimentModalSheetViewModel?, delegate: WMFAltTextExperimentModalSheetDelegate?, loggingDelegate: WMFAltTextExperimentModalSheetLoggingDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.loggingDelegate = loggingDelegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var tooltip2SourceView: UIView? {
        return modalSheetView?.fileNameLabel.superview
    }
    
    public var tooltip2SourceRect: CGRect? {
        
        guard let modalSheetView else {
            return nil
        }
        
        let fileNameRect = modalSheetView.fileNameLabel.frame
        return CGRect(x: fileNameRect.minX + 30, y: fileNameRect.minY, width: 0, height: 0)
    }
    
    public var tooltip3SourceView: UIView? {
        return modalSheetView?.textView.superview
    }
    
    public var tooltip3SourceRect: CGRect? {
        return modalSheetView?.textView.frame
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let viewModel else { return }
        let view = WMFAltTextExperimentModalSheetView(frame: UIScreen.main.bounds, viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
        self.modalSheetView = view
        addComponent(view, pinToEdges: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loggingDelegate?.didAppear()
    }
}

extension WMFAltTextExperimentModalSheetViewController: WMFTooltipPresenting {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        // Tooltips are only allowed to dismiss via Next buttons
        if presentationController.presentedViewController is WMFTooltipViewController {
            return false
        }
        
        return true
    }
}
