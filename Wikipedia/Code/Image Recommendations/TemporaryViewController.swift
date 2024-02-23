import UIKit
import Components

// class used until we have the controller that will host this one
class TemporaryViewController: ViewController {

    let text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

    let bottomVC = WKBottomSheetViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomVC.view.backgroundColor = .gray
        bottomVC.isModalInPresentation = true

        // TODO: adjust for iPad https://developer.apple.com/videos/play/wwdc2021/10063/
        if let sheet = bottomVC.sheetPresentationController {

            sheet.detents = [ .medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24.0
        }
        navigationController?.present(bottomVC, animated: false)
    }

}

