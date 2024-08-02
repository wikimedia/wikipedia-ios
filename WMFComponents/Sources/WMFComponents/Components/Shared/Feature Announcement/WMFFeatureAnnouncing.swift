import Foundation
import UIKit
import SwiftUI

public protocol WKFeatureAnnouncing {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel, sourceView: UIView, sourceRect: CGRect)
}

public extension WKFeatureAnnouncing where Self:UIViewController {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel, sourceView: UIView, sourceRect: CGRect) {
        let oldPrimaryAction = viewModel.primaryButtonAction
        viewModel.primaryButtonAction = { [weak self] in
            self?.dismiss(animated: true) {
                oldPrimaryAction()
            }
        }
        
        let oldCloseAction = viewModel.closeButtonAction
        viewModel.closeButtonAction = { [weak self] in
            self?.dismiss(animated: true) {
                oldCloseAction?()
            }
        }
        
        let viewController = WKFeatureAnnouncementViewController(viewModel: viewModel)
        
        viewController.modalPresentationStyle = .popover
        if let popover = viewController.popoverPresentationController {
            
            popover.sourceView = sourceView
            popover.sourceRect = sourceRect
            
            let sheet = popover.adaptiveSheetPresentationController
            sheet.detents = [.medium()]
            
            present(viewController, animated: true)
        }
        
        
    }
}
