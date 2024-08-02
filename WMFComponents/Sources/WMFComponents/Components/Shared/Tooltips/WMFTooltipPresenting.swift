import Foundation
import UIKit

/// A protocol meant for UIViewControllers to present tooltips. It is set up to handle the dismiss and presentation cycle through the tooltip view models via default protocol implementions.
public protocol WMFTooltipPresenting: UIAdaptivePresentationControllerDelegate {
    var tooltipViewModels: [WMFTooltipViewModel] { get set }
    func displayTooltips(tooltipViewModels: [WMFTooltipViewModel])
}

// Note: WMFTooltipPresenting VC must also implement UIAdaptivePresentationControllerDelegate adaptivePresentationStyle methods (returning .none) for proper tooltip display. Unfortunately this implementation cannot be handled via a protocol extension.
public extension WMFTooltipPresenting where Self: UIViewController {
    func displayTooltips(tooltipViewModels: [WMFTooltipViewModel]) {
        self.tooltipViewModels = tooltipViewModels
        for tooltipViewModel in self.tooltipViewModels {
            let oldAction = tooltipViewModel.buttonAction
            tooltipViewModel.buttonAction = { [weak self] in
                
                self?.dismiss(animated: true, completion: {
                    self?.tooltipViewModels.removeFirst()
                    self?.displayNextTooltip()
                })
                
                oldAction?()
            }
        }
        
        displayNextTooltip()
    }
    
    fileprivate func displayNextTooltip() {
        guard let viewModel = tooltipViewModels.first else {
            return
        }
        
        let tooltip = WMFTooltipViewController(viewModel: viewModel)
        tooltip.modalPresentationStyle = .popover
        if let presentationController = tooltip.presentationController {
            presentationController.delegate = self
        }
        
        tooltip.popoverPresentationController?.sourceView = viewModel.sourceView
        tooltip.popoverPresentationController?.sourceRect = viewModel.sourceRect
        tooltip.popoverPresentationController?.permittedArrowDirections = viewModel.permittedArrowDirections

        present(tooltip, animated: true)
    }
}
