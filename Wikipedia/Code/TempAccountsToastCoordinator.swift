import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@objc(TempAccountsToastCoordinator)
final class TempAccountsToastCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController
    var didTapReadMore: () -> Void
    var didTapClose: () -> Void
    
    public init(navigationController: UINavigationController, didTapReadMore: @escaping () -> Void, didTapClose: @escaping () -> Void) {
        self.navigationController = navigationController
        self.didTapReadMore = didTapReadMore
        self.didTapClose = didTapClose
    }
    
    func start() {
        print("coordinator")
    }
    
    private func presentToast() {
        let viewModel = WMFTempAccountsToastViewModel(didTapReadMore: {
            
        }, didTapClose: { [weak self] in
            self?.navigationController.dismiss(animated: true)
        })
        
        let toast = WMFTempAccountsToastView(viewModel: viewModel)
        
    }
}
