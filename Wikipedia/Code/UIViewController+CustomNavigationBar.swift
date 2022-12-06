import Foundation
import Combine

protocol CustomNavigationBarSubview: UIView {
    var collapseOrder: Int { get }
    
    func updateContentOffset(contentOffset: CGPoint)
}

class CustomNavigationBarContentOffset: ObservableObject {
    @Published var point: CGPoint = .zero
}

protocol CustomNavigationBarContainerViewController: UIViewController {
    var stackedNavigationViews: [CustomNavigationBarSubview] { get }
    var contentOffset: CustomNavigationBarContentOffset { get }
    var contentOffsetCancellable: AnyCancellable? { get set }
}

extension CustomNavigationBarContainerViewController {
    
    // TODO: better name?
    func setupCustomNavigationBar(withChildViewController childVC: UIViewController) {
        
        guard viewIfLoaded != nil else {
            assertionFailure("View not loaded")
            return
        }
        
        navigationController?.isNavigationBarHidden = true
        
        // First add child VC
        addChild(childVC)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childVC.view)
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: childVC.view.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: childVC.view.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: childVC.view.bottomAnchor)
        ])
        childVC.didMove(toParent: self)
        
        // Then add custom navigation bar above
        let navigationBar = CustomNavigationBar(frame: .zero)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(navigationBar)
        
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: navigationBar.topAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            childVC.view.topAnchor.constraint(equalTo: navigationBar.bottomAnchor)
        ])
        
        navigationBar.addCollapsingSubviews(views: stackedNavigationViews)
        
        self.contentOffsetCancellable = contentOffset.$point.sink { newOffset in
            self.stackedNavigationViews.forEach { subview in
                subview.updateContentOffset(contentOffset: newOffset)
            }
        }
    }
}
