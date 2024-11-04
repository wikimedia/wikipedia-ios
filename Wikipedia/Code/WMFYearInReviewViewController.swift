import WMF
import SwiftUI
import CocoaLumberjackSwift
import WMFComponents
import WMFData
import UIKit
import Foundation

fileprivate final class WMFYearInReviewHostingController: WMFComponentHostingController<WMFYearInReviewView> {
    init(viewModel: WMFYearInReviewViewModel) {
        super.init(rootView: WMFYearInReviewView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WMFYearInReviewViewController: WMFCanvasViewController {
    private let hostingViewController: WMFYearInReviewHostingController
    private let viewModel: WMFYearInReviewViewModel

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
        self.hostingViewController = WMFYearInReviewHostingController(viewModel: viewModel)
        super.init()

        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingViewController.didMove(toParent: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
