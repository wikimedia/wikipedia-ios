import Foundation
import UIKit
import SwiftUI

public protocol WKFeatureAnnouncing {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel, theme: WKTheme)
}

public extension WKFeatureAnnouncing where Self:UIViewController {
    func announceFeature(viewModel: WKFeatureAnnouncementViewModel, theme: WKTheme) {
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
        
        let rootView = WKFeatureAnnouncementView(viewModel: viewModel)
        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.modalPresentationStyle = .pageSheet
        hostingVC.view.backgroundColor = theme.paperBackground
        if let sheet = hostingVC.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(hostingVC, animated: true)
    }
}
