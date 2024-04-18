import Foundation
import UIKit
import SwiftUI

public protocol WKFeatureAnnouncing {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel)
}

public extension WKFeatureAnnouncing where Self:UIViewController {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel) {
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
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(viewController, animated: true)
    }
}
