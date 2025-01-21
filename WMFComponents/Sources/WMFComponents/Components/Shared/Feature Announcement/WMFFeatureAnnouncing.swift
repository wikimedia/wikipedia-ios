import Foundation
import UIKit
import SwiftUI

public protocol WMFFeatureAnnouncing {
    func announceFeature(viewModel: WMFFeatureAnnouncementViewModel, sourceView: UIView?, sourceRect: CGRect?, barButtonItem: UIBarButtonItem?)
}

public extension WMFFeatureAnnouncing where Self:UIViewController {
    func announceFeature(viewModel: WMFFeatureAnnouncementViewModel, sourceView: UIView?, sourceRect: CGRect?, barButtonItem: UIBarButtonItem?) {
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
        
        let viewController = WMFFeatureAnnouncementViewController(viewModel: viewModel)
        
        viewController.modalPresentationStyle = .popover
        if let popover = viewController.popoverPresentationController {

            var canPresentWithoutCrashing = false
            if let sourceView, let sourceRect {
                popover.sourceView = sourceView
                popover.sourceRect = sourceRect
                canPresentWithoutCrashing = true
            } else if let barButtonItem {
                popover.barButtonItem = barButtonItem
                canPresentWithoutCrashing = true
            }
            
            guard canPresentWithoutCrashing else { return }

            let sheet = popover.adaptiveSheetPresentationController
            
            let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("slightlyTallerMedium")) { context in
                return context.maximumDetentValue * 0.65
            }
            
            sheet.detents = [customDetent]
            sheet.selectedDetentIdentifier = customDetent.identifier

            present(viewController, animated: true)
        }
    }
}
